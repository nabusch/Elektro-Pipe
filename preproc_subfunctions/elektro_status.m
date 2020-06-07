function [] = elektro_status(msg)
%
% wm: THIS FUNCTION STILL NEEDS A PROPER DOCUMENTATION!

% (c) Niko Busch & Wanja Mössing
% (contact: niko.busch@gmail.com, w.a.moessing@gmail.com)
%
%  This program is free software: you can redistribute it and/or modify
%  it under the terms of the GNU General Public License as published by
%  the Free Software Foundation, either version 3 of the License, or
%  (at your option) any later version.
%
%  This program is distributed in the hope that it will be useful,
%  but WITHOUT ANY WARRANTY; without even the implied warranty of
%  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%  GNU General Public License for more details.
%
%  You should have received a copy of the GNU General Public License
%  along with this program. If not, see <http://www.gnu.org/licenses/>.


fprintf(['\n\n\n', repmat('%', 1, 80), '\n',...
    'Elektro-Status: %s\n',...
    repmat('%', 1, 80), '\n\n'], msg);
end

