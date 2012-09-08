Silicon Valley Readme

Contents
1 About Silicon Valley
2 Details and Gameplay Tips
3 License
4 Credits


1 About Silicon Valley
======================

Silicon Valley is a GameScript for OpenTTD 1.3 or newer.

It challenges every company to turn a specific town into a global production
centre for a specialised cargo. Every company is assigned a slightly different
goal, but they all have the same time period to achieve their goal. To achieve
the goal, the companies do not only have to transport lots of cargo to and from
their town, they also have to fund sufficient industries to produce the cargo.



2 Details and Gameplay Tips
===========================

Via the script settings the detailed goal parameters can be configured.

* A time frame to complete the goal and achieve a Gold Medal.
  To achive Silver or Bronze Medals the companies have 50% resp. 100% more
  time.
* The type of cargo to use for the challenge, either Primary, Secondary or
  Any type.
* The number of industries which must be present in the town to process the
  cargo. If there are not enough industries (the usual case), the companies
  have to fund them themself.
* The minimal amount of cargo the company has to service for each of the
  industries to make them count for the goal.
* The total amount of cargo the company has to service at the town to
  achieve the goal.

If you have trouble to deliver cargo to a specific industry (when there are
multiple industries nearby), make sure that the station sign is directly
adjacent to an industry tile. (Yes, you will need one station per industry.)

Important for games with a short goal time:
Since the companies have to fund industries you should add a NewGRF which
significantly lowers the cost to fund industries.
For example 'BaseCost Mod" with these settings:
* "Funding industries" -> "quarter"
* "Build raw industries" -> "3"



3 License
=========

Silicon Valley
Copyright (C) 2012  Christoph Elsenhans

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License version 2 as published by the Free
Software Foundation.

This program is distributed in the hope that it will be useful, but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License
for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the

Free Software Foundation, Inc.
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.



4 Credits
=========

Authors:
   Code:             Christoph Elsenhans (aka frosch)
   GS framework:     Leif Linse (aka Zuu)

Translations:
   Here could be your name! :)
