%% s_sceneRoi
%
% Illustrate getting various types of scene data from  ROIs
% Cases for photons, energy, illuminant and reflectance are shown
%
% BW Copyright VISTASOFT Team, 2014

%% 
s_initISET

%% Create a scene
scene = sceneCreate;
w = sceneGet(scene,'wave');

%% Photons
sz = sceneGet(scene,'size');
roi = round( [sz(1)/2, sz(2), 10, 10]);
p = sceneGet(scene,'roi photons',roi);

vcNewGraphWin;
plot(w,p);
xlabel('Wavelength (nm)');
ylabel('Photons/s/sr/nm/m^2');
grid on

%% Energy
e = sceneGet(scene,'roi energy',roi);

vcNewGraphWin;
plot(w,e);
xlabel('Wavelength (nm)');
ylabel('Watts/s/sr/nm/m^2');
grid on

%% Reflectance as XW matrix, but derived here
photons       = sceneGet(scene,'roi photons', roi);
illuminantSPD = sceneGet(scene,'roi illuminant photons',roi);
reflectance   = photons ./ illuminantSPD;

vcNewGraphWin;
plot(w,reflectance);
xlabel('Wavelength (nm)');
ylabel('Reflectance');
grid on


%% As above, but by the get directly

r = sceneGet(scene,'roi reflectance', roi);

% Now compare
vcNewGraphWin;
plot(r(:),reflectance(:),'o');
title('Should be identity line');
axis equal; grid on; identityLine;


%% Region of interest for mean reflectance
r = sceneGet(scene,'roi mean reflectance',roi);

vcNewGraphWin;
plot(w,r);
xlabel('Wavelength (nm)');
ylabel('Watts/s/sr/nm/m^2');
grid on

%%  Compute the mean reflectance here and compare

r2 = mean(r,1);
vcNewGraphWin;
plot(w,r,'k-',w,r2,'r--');
xlabel('Wavelength (nm)');
ylabel('Reflectance');
grid on

%% Mean illuminant in an ROI

illuminantSPD = sceneGet(scene,'roi illuminant photons',roi);

vcNewGraphWin;
plot(w,illuminantSPD);
xlabel('Wavelength (nm)');
ylabel('Photons/s/sr/nm/m^2');
grid on
        
%% End