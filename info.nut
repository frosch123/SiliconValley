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

require("version.nut");

class FMainClass extends GSInfo {
	function GetAuthor()		{ return "frosch"; }
	function GetName()			{ return "SiliconValley"; }
	function GetDescription() 	{ return "SiliconValley"; }
	function GetVersion()		{ return SELF_VERSION; }
	function GetDate()			{ return SELF_DATE; }
	function CreateInstance()	{ return "MainClass"; }
	function GetShortName()		{ return "SIVY"; }
	function GetAPIVersion()	{ return "1.3"; }
	function GetUrl()			{ return "http://dev.openttdcoop.org/projects/siliconvalley"; }

	function GetSettings() {
		AddSetting({
				name = "time_frame",
				description = "Number of years to archieve the Gold Medal",
				min_value = 1, max_value = 1000,
				easy_value = 10, medium_value = 10, hard_value = 10, custom_value = 10,
				flags = CONFIG_NONE,
			});
		AddSetting({
				name = "cargo_type",
				description = "Challenged cargo type",
				min_value = 1, max_value = 3,
				easy_value = 2, medium_value = 2, hard_value = 2, custom_value = 2,
				flags = CONFIG_NONE,
			});
		AddLabels("cargo_type", {_1 = "primary", _2 = "secondary", _3 = "any"});
		AddSetting({
				name = "industry_amount",
				description = "Amount of industries required in the target area",
				min_value = 1, max_value = 100,
				easy_value = 2, medium_value = 5, hard_value = 10, custom_value = 5,
				flags = CONFIG_NONE,
			});
		AddSetting({
				name = "min_amount",
				description = "Minimum amount of cargo to produce/transport per industry within a quarter",
				min_value = 1, max_value = 100000,
				easy_value = 100, medium_value = 100, hard_value = 100, custom_value = 100,
				flags = CONFIG_NONE,
			});
		AddSetting({
				name = "total_amount",
				description = "Amount of cargo to produce/transport within a quarter",
				min_value = 1, max_value = 1000000,
				easy_value = 3000, medium_value = 7000, hard_value = 10000, custom_value = 7000,
				flags = CONFIG_NONE,
			});
	}
}

RegisterGS(FMainClass());
