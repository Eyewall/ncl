;--------------------------------------------------
;Patrick Duran
;01 January 2018
;
;Plots the propagation angle of a gravity wave as a
;function of the squared Brunt-Vaisala frequency
;for a prescribed wave period and latitude.
;Uses Eq. 4 of O'Neill et al. (Aug. 2017, JAS).
;--------------------------------------------------

lat = 15  ;Latitude (degrees North)
per = 24   ;Period of gravity wave (hours)

sidday= 86164.1          ;Length of sidereal day (s)
pi    = 3.141592         ;Pi
omega = 2*pi/sidday      ;Angular freq of earth
rlat  = lat*(2*pi/360)   ;Convert lat to radians
freq  = 2*pi/(per*sidday/24)  ;Compute wave frequency
f     = 2*omega*sin(rlat) ;Compute Coriolis param
n2    = fspan(10^-5,10^-4,10)
angle = atan(sqrt(n2/(freq^2-f^2)))/(2*pi/360)
test = n2/(freq^2-f^2)
;test = sqrt(n2/(freq^2-f^2))
;print( test)
print( n2)
print( angle)
