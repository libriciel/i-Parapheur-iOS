/*
 * i-Parapheur iOS
 * Copyright (C) 2012-2020 Libriciel-SCOP
 * Contributors : SKROBS (2012)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as
 * published by the Free Software Foundation, either version 3 of the
 * License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */
#define kSelectBureauAppeared @"selectBureauAppeared"
#define kFilterChanged @"filterChanged"

#define SHOW_HUD \
LGViewHUD *hud = [LGViewHUD defaultHUD]; \
hud.image=[UIImage imageNamed:@"rounded-checkmark.png"]; \
hud.topText=@""; \
hud.bottomText=@"Chargement ..."; \
hud.activityIndicatorOn=YES; \
[hud setDelegate:self]; \
[hud showInView:self.view];

#define HIDE_HUD \
[[LGViewHUD defaultHUD] hideWithAnimation:HUDAnimationHideFadeOut];