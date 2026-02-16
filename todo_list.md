
# TODO LIST
- Get an idea of how much of the dynamics are from noise vs input
- Compare different models and decide which to use
- Train models on constant aplitude interval. Check when poles/zeros converge. Check pole/zero uncertainty
- Fit models on reasonable length interval of data with different amplitudes. Examine difference in dynamics

# Våra val


# ATT FÅ GJORT
- förändring av dynamik beroende amplitud?
- Använda konstant period för att utvärdera hur långt intervall som krävs. Kolla konvergens. Kolla osäkerhet
- Processmodell vs Störningsmodell
verifieera lågstör
bipunkt
- Värt att ha separat störningsmodell vs arx?

- 
## gemini comments
Data Analysis

- SNLS80mV.csv: This file contains time-series data where V1 is the input and V2 is the output. The "SNLS" likely stands for a signal type (e.g., Static Non-Linearity Sine or similar) with an amplitude of 80mV. This dataset is typically used for validation or for analyzing the static non-linear curve of the system.
- Schroeder80mV.mat: This file contains a Schroeder phase multisine experiment. As noted in the README.txt, this signal is designed to excite specific frequencies (odd bins) with a flat amplitude spectrum and low crest factor. It is ideal for frequency domain identification and estimating the linear Frequency Response Function (FRF).

