/*
 * This file is part of SiliconValley, which is a GameScript for OpenTTD
 * Copyright (C) 2012  Christoph Elsenhans
 *
 * Original copyright of MinimalGS: Copyright (C) 2012  Leif Linse
 *
 * SiliconValley is free software; you can redistribute it and/or modify it 
 * under the terms of the GNU General Public License as published by
 * the Free Software Foundation; version 2 of the License
 *
 * SiliconValley is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with SiliconValley; If not, see <http://www.gnu.org/licenses/> or
 * write to the Free Software Foundation, Inc., 51 Franklin Street, 
 * Fifth Floor, Boston, MA 02110-1301 USA.
 *
 */

import("util.superlib", "SuperLib", 25);
Helper <- SuperLib.Helper;

class MainClass extends GSController 
{
	_load_data = null;

	primary_cargos = GSList();
	secondary_cargos = GSList();
	company_town = null;
	industry_town = GSList();

	company_goal = array(GSCompany.COMPANY_LAST, {});
	last_month = 0;

	constructor()
	{
	}
}

function MainClass::TableFromList(list)
{
	local result = {};
	foreach (key, val in list)
	{
		result.rawset(key, val);
	}
	return result;
}

function MainClass::ListFromTable(table)
{
	local result = GSList();
	foreach (key, val in table)
	{
		result.AddItem(key, val);
	}
	return result;
}

function MainClass::Save()
{
	GSLog.Info("Saving data to savegame");
	return {
		sv_company_town = this.company_town,
		sv_company_goal = this.company_goal,
		sv_last_month = last_month,
	};
}

function MainClass::Load(version, tbl)
{
	GSLog.Info("Loading data from savegame made with version " + version + " of the game script");

	foreach(key, val in tbl)
	{
		if (key == "sv_company_town") this.company_town = val;
		if (key == "sv_company_goal") this.company_goal = val;
		if (key == "sv_last_month") this.last_month = val;
	}
}

function MainClass::Start()
{
	// Wait for the game to start
	this.Sleep(1);

	this.PostInit();

	while (true) {
		local loop_start_tick = GSController.GetTick();

		this.HandleEvents();
		this.DoTest();

		// Loop with a frequency of five days
		local ticks_used = GSController.GetTick() - loop_start_tick;
		this.Sleep(Helper.Max(1, 5 * 74 - ticks_used));
	}
}

function MainClass::HandleEvents()
{
	while(GSEventController.IsEventWaiting())
	{
		local ev = GSEventController.GetNextEvent();

		if(ev == null)
			return;
	}
}

function MainClass::PostInit()
{
	/* Classify cargos */
	local indtypes = GSIndustryTypeList();
	for (local it = indtypes.Begin(); !indtypes.IsEnd(); it = indtypes.Next())
	{
		if (GSIndustryType.IsRawIndustry(it))
		{
			this.primary_cargos.AddList(GSIndustryType.GetProducedCargo(it));
		}
		else if (!GSIndustryType.GetAcceptedCargo(it).IsEmpty())
		{
			this.secondary_cargos.AddList(GSIndustryType.GetProducedCargo(it));
		}
	}
	local indefinite_cargos = GSList();
	indefinite_cargos.AddList(this.primary_cargos);
	indefinite_cargos.KeepList(this.secondary_cargos);
	this.primary_cargos.RemoveList(indefinite_cargos);
	this.secondary_cargos.RemoveList(indefinite_cargos);

	GSLog.Info("Primary cargos:");
	for (local it = this.primary_cargos.Begin(); !this.primary_cargos.IsEnd(); it = this.primary_cargos.Next())
	{
		GSLog.Info(GSCargo.GetCargoLabel(it));
	}

	GSLog.Info("Secondary cargos:");
	for (local it = this.secondary_cargos.Begin(); !this.secondary_cargos.IsEnd(); it = this.secondary_cargos.Next())
	{
		GSLog.Info(GSCargo.GetCargoLabel(it));
	}

	GSLog.Info("Indefinite cargos:");
	for (local it = indefinite_cargos.Begin(); !indefinite_cargos.IsEnd(); it = indefinite_cargos.Next())
	{
		GSLog.Info(GSCargo.GetCargoLabel(it));
	}

	local other_cargos = GSCargoList();
	other_cargos.RemoveList(this.primary_cargos);
	other_cargos.RemoveList(this.secondary_cargos);
	other_cargos.RemoveList(indefinite_cargos);
	GSLog.Info("Other cargos:");
	for (local it = other_cargos.Begin(); !other_cargos.IsEnd(); it = other_cargos.Next())
	{
		GSLog.Info(GSCargo.GetCargoLabel(it));
	}

	/* Classify towns */
	local small_towns = GSList();
	for (local x = 8; x < GSMap.GetMapSizeX(); x += 16)
	{
		for (local y = 8; y < GSMap.GetMapSizeY(); y += 16)
		{
			local tile = GSMap.GetTileIndex(x, y);
			if (GSTile.IsWaterTile(tile)) continue;
			local town = GSTile.GetClosestTown(tile);
			if (small_towns.HasItem(town))
			{
				small_towns.SetValue(town, small_towns.GetValue(town) + 1);
			}
			else
			{
				small_towns.AddItem(town, 1);
			}
		}
	}
	small_towns.Sort(GSList.SORT_BY_VALUE, GSList.SORT_ASCENDING);
	small_towns.KeepAboveValue(GSController.GetSetting("industry_amount") + 2);
	small_towns.KeepBottom(GSCompany.COMPANY_LAST - GSCompany.COMPANY_FIRST);
	GSLog.Info("Towns:");
	for (local it = small_towns.Begin(); !small_towns.IsEnd(); it = small_towns.Next())
	{
		GSLog.Info("" + small_towns.GetValue(it) + " " + GSTown.GetName(it));
	}

	if (small_towns.Count() < GSCompany.COMPANY_LAST - GSCompany.COMPANY_FIRST)
	{
		GSLog.Warning("Only " + small_towns.Count() + " towns found!");
		GSGoal.Question(1, GSCompany.COMPANY_INVALID, GSText(GSText.STR_TOO_FEW_TOWNS, small_towns.Count()), GSGoal.QT_WARNING, GSGoal.BUTTON_CONTINUE);
	}

	/* Assigns towns, if not loaded from savegame */
	if (this.company_town == null)
	{
		this.company_town = array(GSCompany.COMPANY_LAST);
		local cid = GSCompany.COMPANY_FIRST;
		for (local it = small_towns.Begin(); !small_towns.IsEnd(); it = small_towns.Next(), cid++)
		{
			this.company_town[cid] = it;
		}
	}

	/* Check game settings */
	if (GSController.GetSetting("cargo_type") & 1)
	{
		/* Goal has primary cargos, enable funding primary industries */
		if (GSGameSettings.IsValid("construction.raw_industry_construction"))
		{
			GSGameSettings.SetValue("construction.raw_industry_construction", 1);
		}
	}
	/* Enable multiple industries per town */
	if (GSGameSettings.IsValid("economy.multiple_industry_per_town"))
	{
		GSGameSettings.SetValue("economy.multiple_industry_per_town", 1);
	}
	/* Disable founding of towns */
	if (GSGameSettings.IsValid("economy.found_town"))
	{
		GSGameSettings.SetValue("economy.found_town", 0);
	}
}

function MainClass::DoTest()
{
	/* Update town cache */
	local indlist = GSIndustryList();
	this.industry_town.KeepList(indlist);
	indlist.RemoveList(this.industry_town);
	for (local it = indlist.Begin(); !indlist.IsEnd(); it = indlist.Next())
	{
		this.industry_town.AddItem(it, GSTile.GetClosestTown(GSIndustry.GetLocation(it)));
	}

	local cur_month = GSDate.GetMonth(GSDate.GetCurrentDate());
	local new_quarter = false;
	if (cur_month != this.last_month)
	{
		this.last_month = cur_month;
		new_quarter = (cur_month == 1 || cur_month == 4 || cur_month == 7 || cur_month == 10);
	}

	/* Process companies */
	for (local cid = GSCompany.COMPANY_FIRST; cid < GSCompany.COMPANY_LAST; cid++)
	{
		if (GSCompany.ResolveCompanyID(cid) != GSCompany.COMPANY_INVALID)
		{
			if (this.company_goal[cid].len() == 0)
			{
				InitNewCompany(cid);
			}

			UpdateMonitors(cid);

			if (new_quarter) NextQuarter(cid);

			UpdateGoals(cid);
		}
		else if (this.company_goal[cid].len() != 0)
		{
			/* Clear dead company */
			GSLog.Info("Clear company " + cid);
			CancelMonitors(cid);
			this.company_goal[cid] = {};
		}
	}
}

function MainClass::InitNewCompany(cid)
{
	/* Collect cargotypes */
	local cargos = GSList();
	if (GSController.GetSetting("cargo_type") & 1) cargos.AddList(this.primary_cargos);
	if (GSController.GetSetting("cargo_type") & 2) cargos.AddList(this.secondary_cargos);

	/* Check usability */
	local fundable_cargos = GSList();
	local indlist = GSIndustryTypeList();
	for (local indtype = indlist.Begin(); !indlist.IsEnd(); indtype = indlist.Next())
	{
		if (GSIndustryType.CanBuildIndustry(indtype))
		{
			fundable_cargos.AddList(GSIndustryType.GetProducedCargo(indtype));
		}
	}
	cargos.KeepList(fundable_cargos);

	/* Select cargo */
	local goal = this.company_goal[cid];
	if (cargos.IsEmpty() || this.company_town.len() <= cid)
	{
		/* Mark as failed */
		goal.cargo_type <- -1;
		goal.town <- -1;
		GSLog.Error("Failed to find suitable goal cargo!");
		GSGoal.Question(2, cid, GSText(GSText.STR_NO_CARGO), GSGoal.QT_ERROR, GSGoal.BUTTON_SURRENDER);
	}
	else
	{
		cargos.Valuate(GSBase.RandItem);
		cargos.Sort(GSList.SORT_BY_VALUE, GSList.SORT_ASCENDING);
		local cargo = cargos.Begin();
		goal.cargo_type <- cargo;
		goal.town <-this.company_town[cid];
		GSLog.Info("Assign cargo " + cargo + " to company " + cid);
		GSGoal.Question(2, cid, GSText(GSText.STR_GOAL_START, 1 << cargo, goal.town, 1 << cargo), GSGoal.QT_INFORMATION, GSGoal.BUTTON_GO);
	}

	goal.cargo_mask <- 1 << goal.cargo_type;
	goal.cur_industry_amount <- 0;
	goal.last_min_amount <- 0;
	goal.last_total_amount <- 0;
	goal.monitors <- {};

	goal.goal_industry_amount <- GSGoal.GOAL_INVALID;
	goal.goal_min_amount <- GSGoal.GOAL_INVALID;
	goal.goal_total_amount <- GSGoal.GOAL_INVALID;
	goal.goal_total_months <- GSGoal.GOAL_INVALID;

	goal.cached_cur_industry_amount <- -1;
	goal.cached_last_min_amount <- -1;
	goal.cached_last_total_amount <- -1;
	goal.cached_total_months <- -1;
	goal.cached_medal <- -1;

	goal.start <- GSDate.GetCurrentDate();
	goal.won <- 0;
}

function MainClass::QueryMonitor(ind, cid, cargo_type)
{
	return GSCargoMonitor.GetIndustryPickupAmount(cid, cargo_type, ind, true);
}

function MainClass::UpdateMonitors(cid)
{
	local goal = this.company_goal[cid];

	local indlist = GSList();
	indlist.AddList(this.industry_town);
	indlist.KeepValue(goal.town);
	indlist.KeepList(GSIndustryList_CargoProducing(goal.cargo_type));

	goal.cur_industry_amount = indlist.Count();

	indlist.Valuate(this.QueryMonitor, cid, goal.cargo_type);

	foreach(key, val in goal.monitors)
	{
		if (indlist.HasItem(key))
		{
			indlist.SetValue(key, indlist.GetValue(key) + val);
		}
		else
		{
			GSCargoMonitor.GetIndustryPickupAmount(cid, goal.cargo_type, key, false);
		}
	}

	goal.monitors = this.TableFromList(indlist);
}

function MainClass::CancelMonitors(cid)
{
	local goal = this.company_goal[cid];
	foreach(key, val in goal.monitors)
	{
		GSCargoMonitor.GetIndustryPickupAmount(cid, goal.cargo_type, key, false);
	}
}

function MainClass::GetMedal(start, end)
{
	local result = { };

	result.passed_total_months <- (GSDate.GetYear(end) - GSDate.GetYear(start)) * 12 + GSDate.GetMonth(end) - GSDate.GetMonth(start);
	result.passed_years <- result.passed_total_months / 12;
	result.passed_months <- result.passed_total_months % 12;

	result.medal <- GSText.STR_WON_FAIL;
	result.left_total_months <- 0;
	result.goal_date <- 0;

	local goal_years = GSController.GetSetting("time_frame");
	local goal_months = goal_years * 12;

	if (result.passed_total_months < goal_months)
	{
		result.medal = GSText.STR_WON_GOLD;
		result.left_total_months = goal_months - result.passed_total_months;
		result.goal_date = GSDate.GetDate(GSDate.GetYear(start) + goal_years, GSDate.GetMonth(start), 1);
	}
	else if (result.passed_total_months < goal_months * 3 / 2)
	{
		result.medal = GSText.STR_WON_SILVER;
		result.left_total_months = goal_months * 3 / 2 - result.passed_total_months;
		local goal_year = GSDate.GetYear(start) + (goal_months * 3 / 2) / 12;
		local goal_month = GSDate.GetMonth(start) + (goal_months * 3 / 2) % 12;
		if (goal_month > 12)
		{
			goal_year++;
			goal_month -= 12;
		}
		result.goal_date = GSDate.GetDate(goal_year, goal_month, 1);
	}
	else if (result.passed_total_months < goal_months * 2)
	{
		result.medal = GSText.STR_WON_BRONCE;
		result.left_total_months = goal_months * 2 - result.passed_total_months;
		result.goal_date = GSDate.GetDate(GSDate.GetYear(start) + goal_years * 2, GSDate.GetMonth(start), 1);
	}

	result.left_years <- result.left_total_months / 12;
	result.left_months <- result.left_total_months % 12;

	return result;
}

function MainClass::NextQuarter(cid)
{
	GSLog.Info("Quarter summary for company " + cid);
	local goal = this.company_goal[cid];

	local industry_amount = GSController.GetSetting("industry_amount");
	local min_amount = GSController.GetSetting("min_amount");
	local total_amount = GSController.GetSetting("total_amount");

	goal.last_min_amount = 0;
	goal.last_total_amount = 0;

	foreach(key, val in goal.monitors)
	{
		if (val > 0) GSLog.Info("Transported cargo for industry " + key + ": " + val);
		if (val >= min_amount) goal.last_min_amount++;
		goal.last_total_amount += val;
		goal.monitors.rawset(key, 0);
	}

	GSLog.Info("win date: " + goal.won);
	GSLog.Info("min_amount: " + goal.last_min_amount + " / " + industry_amount);
	GSLog.Info("total_amount: " + goal.last_total_amount + " / " + total_amount);
	if (goal.won == 0 && goal.last_min_amount >= industry_amount && goal.last_total_amount >= total_amount)
	{
		GSLog.Info("Company won: " + cid);
		goal.won = GSDate.GetCurrentDate();
		local medal = GetMedal(goal.start, goal.won);
		GSGoal.Question(3, cid, GSText(GSText.STR_WON, medal.passed_years, medal.passed_months, GSText(medal.medal)), GSGoal.QT_INFORMATION, GSGoal.BUTTON_ACCEPT);

		GSNews.Create(GSNews.NT_GENERAL, GSText(GSText.STR_WON_NEWS, goal.cargo_mask, medal.passed_years, medal.passed_months, cid, goal.town, goal.cargo_mask), GSCompany.COMPANY_INVALID);
	}
}

function MainClass::UpdateGoals(cid)
{
	local goal = this.company_goal[cid];

	local industry_amount = GSController.GetSetting("industry_amount");
	local min_amount = GSController.GetSetting("min_amount");
	local total_amount = GSController.GetSetting("total_amount");

	if (goal.cached_cur_industry_amount != goal.cur_industry_amount)
	{
		if (goal.goal_industry_amount != GSGoal.GOAL_INVALID) GSGoal.Remove(goal.goal_industry_amount);
		goal.goal_industry_amount = GSGoal.New(cid, GSText(GSText.STR_NUM_INDUSTRIES, industry_amount, goal.cargo_mask, goal.town, goal.cur_industry_amount, industry_amount), GSGoal.GT_TOWN, goal.town);
		goal.cached_cur_industry_amount = goal.cur_industry_amount;
	}

	if (goal.cached_last_min_amount != goal.last_min_amount)
	{
		if (goal.goal_min_amount != GSGoal.GOAL_INVALID) GSGoal.Remove(goal.goal_min_amount);
		goal.goal_min_amount = GSGoal.New(cid, GSText(GSText.STR_MIN_PRODUCTION, goal.cargo_type, min_amount, goal.last_min_amount, industry_amount), GSGoal.GT_TOWN, goal.town);
		goal.cached_last_min_amount = goal.last_min_amount;
	}

	if (goal.cached_last_total_amount != goal.last_total_amount)
	{
		if (goal.goal_total_amount != GSGoal.GOAL_INVALID) GSGoal.Remove(goal.goal_total_amount);
		goal.goal_total_amount = GSGoal.New(cid, GSText(GSText.STR_TOTAL_PRODUCTION, goal.cargo_type, total_amount, goal.cargo_type, goal.last_total_amount), GSGoal.GT_TOWN, goal.town);
		goal.cached_last_total_amount = goal.last_total_amount;
	}

	if (goal.won)
	{
		if (goal.goal_total_months != GSGoal.GOAL_INVALID) GSGoal.Remove(goal.goal_total_months);
		goal.goal_total_months = GSGoal.GOAL_INVALID;
	}
	else
	{
		local medal = this.GetMedal(goal.start, GSDate.GetCurrentDate());

		if (goal.cached_total_months != medal.passed_total_months)
		{
			if (goal.goal_total_months != GSGoal.GOAL_INVALID) GSGoal.Remove(goal.goal_total_months);
			if (medal.medal == GSText.STR_WON_FAIL)
			{
				goal.goal_total_months = GSGoal.GOAL_INVALID;
			}
			else
			{
				goal.goal_total_months = GSGoal.New(cid, GSText(GSText.STR_TIME_LEFT, medal.goal_date, GSText(medal.medal), medal.left_years, medal.left_months), GSGoal.GT_NONE, 0);
			}
			goal.cached_total_months = medal.passed_total_months;
		}

		if (goal.cached_medal != medal.medal)
		{
			if (goal.cached_medal != -1)
			{
				GSGoal.Question(3, cid, GSText(GSText.STR_FAIL, GSText(goal.cached_medal), GSText(medal.medal)), GSGoal.QT_INFORMATION, GSGoal.BUTTON_CONTINUE);
			}
			goal.cached_medal = medal.medal;
		}
	}
}
