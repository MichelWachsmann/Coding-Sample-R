---
output: 
  pdf_document:
    citation_package: natbib
    keep_tex: false
    fig_caption: true
    latex_engine: pdflatex
    template: templates/template.tex
header-includes:
  - \usepackage{hyperref}
  - \usepackage{array}
  - \usepackage{caption}
  - \usepackage{graphicx}
  - \usepackage{siunitx}
  - \usepackage[table]{xcolor}
  - \usepackage{multirow}
  - \usepackage{hhline}
  - \usepackage{calc}
  - \usepackage{tabularx}
  - \usepackage{fontawesome}
  - \usepackage{booktabs}
  - \usepackage{float}
  - \floatplacement{table}{H}
  - \usepackage[para,online,flushleft]{threeparttable}
title: "Coding Sample (R)"
author:
  - name: "Author: Michel Wachsmann (FGV EESP)"
date: "March 2026"
geometry: margin=1in
fontfamily: libertine
fontsize: 11pt
---



\bigskip
\bigskip
\noindent
This document presents the results of the Coding Sample (R).
Task 1 examines the dynamic effects of democratic transitions on log GDP per 
capita using a country-year panel dataset. Task 2 develops and implements a 
data-audit strategy for a historical municipal elections dataset, focusing on 
internal consistency, OCR-related errors, and structured validation procedures.

# Task 1 — Event Study / Dynamic Difference-in-Differences

## 1. Introduction

This task examines the effect of regime transitions on economic performance 
using a country-year panel with 184 countries observed between 1970 and 2010. 
The treatment variable is a binary indicator equal to one when a country is 
classified as a democracy and zero otherwise, and the outcome variable is log 
GDP per capita. The main empirical challenge is that treatment is non-absorbing:
countries may transition into democracy and later revert to non-democracy, and 
some countries experience multiple switches over the sample period. This feature
is central both substantively and econometrically.

\medskip\noindent
The analysis proceeds in four steps. First, I motivate the estimator choice. 
Second, I present descriptive evidence on the panel structure and treatment 
variation. Third, I estimate a dynamic event study using the estimator of de 
Chaisemartin and D'Haultfœuille (2020, 2024), which is designed for settings
with treatment switching and heterogeneous dynamic effects. Fourth, I construct 
a stacked difference-in-differences event study as a comparison exercise. 
Throughout, transitions into democracy and transitions out of democracy are 
estimated separately, since the underlying effects are expected to differ not 
only in sign but also in magnitude and timing.

## 2. Data and Descriptive Evidence

The dataset consists of a country-year panel containing a World Bank country 
code, calendar year, a democracy indicator, and log GDP per capita. From this 
panel, I construct lagged democracy status and two transition indicators: 
`trans_in`, equal to one when a country moves from non-democracy to democracy, 
and `trans_out`, equal to one when a country moves from democracy to 
non-democracy.

\medskip\noindent
Before turning to the main estimates, it is useful to describe the aggregate 
evolution of the data. Figure \ref{fig:dem-share} shows the share of countries 
classified as democracies over time. The figure displays a substantial upward 
trend, especially from the late 1980s onward, which is consistent with the 
well-known wave of democratization during the post-Cold War period. This pattern 
also makes clear that treatment timing is staggered rather than concentrated in 
a single period.

\begin{figure}[H]
\includegraphics[width=0.85\linewidth]{../task1/output/figures/fig_dem_share} \caption{Share of Democracies Over Time}\label{fig:dem-share}
\end{figure}

\noindent
Figure \ref{fig:gdp-by-dem} reports mean log GDP per capita by democracy status.
Democracies are richer on average throughout the period. This comparison is 
purely descriptive and should not be interpreted causally, since countries that
are democratic may differ systematically from non-democracies in many dimensions. 
Still, the figure is informative as a first pass and suggests that institutional 
regime type is associated with substantial cross-country differences in income 
levels.

\begin{figure}[H]
\includegraphics[width=0.85\linewidth]{../task1/output/figures/fig_gdp_by_dem} \caption{Mean Log GDP per Capita by Democracy Status}\label{fig:gdp-by-dem}
\end{figure}

\noindent
Figure \ref{fig:first-trans} plots the distribution of first democratization 
years. The timing of first transitions is dispersed across the full sample 
horizon, again underscoring that this is a staggered-adoption environment. This
feature is one of the reasons why simple two-period DID methods would be 
ill-suited to the application.

\begin{figure}[H]
\includegraphics[width=0.85\linewidth]{../task1/output/figures/fig_first_trans} \caption{Distribution of First Democratization Year}\label{fig:first-trans}
\end{figure}

\noindent
Table \ref{tab:summary-stats} presents summary statistics for the main variables.

\begin{table}[H]
\centering
\caption{\label{tab:summary-stats}Summary Statistics}
\centering
\begin{threeparttable}
\begin{tabular}[t]{lrrrrr}
\toprule
Variable & N & Mean & SD & Min & Max\\
\midrule
Log GDP per capita & 6171 & 7.666 & 1.63 & 4.11 & 13.78\\
Democracy & 7544 & 0.478 & 0.50 & 0.00 & 1.00\\
\bottomrule
\end{tabular}
\begin{tablenotes}
\item Country-year panel of 184 countries observed from 1970 to 2010 (41 years). Democracy is a binary indicator equal to 1 if the country is classified as a democracy. Log GDP per capita has 1,373 missing observations (78 countries with at least one missing year). 91 countries experience at least one transition into democracy; 19 of these also experience reversals.
\end{tablenotes}
\end{threeparttable}
\end{table}

\noindent
Taken together, these descriptive statistics and figures suggest three key 
features of the data. First, democracy status evolves substantially over time.
Second, treatment timing is highly staggered. Third, the sample includes both 
democratizations and democratic reversals. Any estimator used in this setting 
must therefore accommodate heterogeneity across cohorts and non-absorbing 
treatment dynamics.

## 3. Estimator Choice

A standard two-way fixed effects event-study estimator is not appropriate in 
this context. With staggered treatment timing and heterogeneous treatment 
effects, TWFE event-study regressions may assign negative weights and use 
already-treated units as controls for newly-treated units. These forbidden 
comparisons distort the causal interpretation of the event-time coefficients. 
The problem is even more severe here because treatment is non-absorbing: 
countries can move into and out of democracy multiple times, so treatment status 
is not monotone.

\medskip\noindent
For this reason, the main specification uses the dynamic 
difference-in-differences estimator of de Chaisemartin and D'Haultfœuille
(2020, 2024). This estimator is designed precisely for environments with 
treatment switching. It compares switchers to valid comparison units while
avoiding the problematic weighting structure of TWFE under heterogeneous 
effects. In the present setting, that makes it the most appropriate baseline 
estimator.

\medskip\noindent
I estimate transitions into democracy and transitions out of democracy 
separately. This separation is important for two reasons. First, the economic 
consequences of democratization and democratic breakdown are unlikely to be 
symmetric. Second, pooling the two directions would blur interpretation by 
averaging together effects that likely differ in sign, timing, and persistence.

\medskip\noindent
As a complementary exercise, I also estimate a stacked event-study design 
following the logic of Cengiz et al. (2019). In this approach, each transition 
event defines a cohort-specific sub-experiment centered around the transition 
year, and the final stacked panel pools these sub-experiments. The stacked DID 
is not the main estimator, but it provides a transparent comparison design and a
useful robustness check.

## 4. Main Results: de Chaisemartin and D'Haultfœuille Event Studies

I begin with the dynamic DID estimates based on de Chaisemartin and 
D'Haultfœuille. Standard errors are clustered at the country level. The 
estimator reports placebo coefficients for pre-transition periods and dynamic
treatment effects for post-transition periods.

### 4.1 Transitions into Democracy

Figure \ref{fig:dcdh-in} presents the event study for transitions into
democracy. The placebo coefficients (periods $-5$ to $-1$) are positive and
statistically significant, with a joint test of nullity rejecting at 
$p = 0.0006$. This indicates a clear violation of the parallel trends 
assumption: countries that democratize were on declining GDP trajectories 
relative to non-switchers in the years before the transition. The 
post-transition effects (periods 1 to 10) are negative, ranging from 
$-0.019$ to $-0.056$, but none is individually significant and the joint 
test fails to reject the null of zero effects ($p = 0.39$).

\begin{figure}[H]
\includegraphics[width=0.9\linewidth]{../task1/output/figures/fig_dcdh_in} \caption{Effect of Transitioning Into Democracy on Log GDP per Capita: de Chaisemartin and D'Haultfœuille}\label{fig:dcdh-in}
\end{figure}

\noindent
The combination of significant pre-trends and insignificant post-treatment 
effects complicates causal interpretation. The negative post-treatment 
coefficients may simply reflect a continuation of the pre-existing relative 
decline rather than a causal effect of democratization. This pattern is 
consistent with the view that economic deterioration often precipitates regime 
change: countries tend to democratize during or after periods of poor economic 
performance relative to stable non-democracies.

### 4.2 Transitions out of Democracy

Figure \ref{fig:dcdh-out} presents the corresponding event study for 
transitions out of democracy. Here the pattern is reversed. The placebo 
coefficients are negative (ranging from $-0.025$ to $-0.139$), with placebo 
periods $-1$ through $-3$ individually significant, though the joint test 
does not reject at conventional levels ($p = 0.16$), likely due to the small 
number of switchers (only 15--16 countries). The post-transition effects are 
positive and increasing over time, reaching $+0.152$ by period 10, with the 
joint test of effects marginally significant ($p = 0.052$).

\begin{figure}[H]
\includegraphics[width=0.9\linewidth]{../task1/output/figures/fig_dcdh_out} \caption{Effect of Transitioning Out of Democracy on Log GDP per Capita: de Chaisemartin and D'Haultfœuille}\label{fig:dcdh-out}
\end{figure}

\noindent
These positive post-transition coefficients indicate that countries losing 
democracy experience GDP \textit{increases} relative to non-switchers. As with 
the switchers-in results, the pre-trend pattern suggests caution. The negative 
placebos imply that countries losing democracy were on improving GDP 
trajectories relative to controls before the reversal. This is consistent with 
the political economy intuition that democratic breakdowns may be more likely 
when incumbent elites have access to growing resources, or when economic 
performance reduces demand for democratic accountability. The small number of 
switchers (15--16 countries) also limits statistical power and the precision of 
these estimates.

### 4.3 Combined Plot

Figure \ref{fig:dcdh-combined} overlays the two sets of dynamic estimates. The
pattern is visually striking in its symmetry: transitions into democracy are 
associated with negative post-treatment coefficients, while transitions out are 
associated with positive ones. Importantly, both directions exhibit pre-trend 
violations of opposite sign, suggesting that regime transitions in both 
directions occur at inflection points in countries' relative economic 
trajectories.

\begin{figure}[H]
\includegraphics[width=0.9\linewidth]{../task1/output/figures/fig_dcdh_combined} \caption{Effect of Democratic Transitions on Log GDP per Capita: Combined de Chaisemartin and D'Haultfœuille Estimates}\label{fig:dcdh-combined}
\end{figure}

\noindent
For completeness, Tables \ref{tab:dcdh-in-table} and \ref{tab:dcdh-out-table} 
report the underlying numerical estimates.

\begin{table}[H]
\centering
\caption{\label{tab:dcdh-in-table}dCDH Estimates: Transitions Into Democracy}
\centering
\begin{threeparttable}
\begin{tabular}[t]{lrrrr}
\toprule
Type & Period & Estimate & Lower 95\% CI & Upper 95\% CI\\
\midrule
Placebo & -5 & 0.0910 & 0.0049 & 0.1772\\
Placebo & -4 & 0.0985 & 0.0268 & 0.1701\\
Placebo & -3 & 0.0864 & 0.0289 & 0.1439\\
Placebo & -2 & 0.0731 & 0.0343 & 0.1120\\
Placebo & -1 & 0.0320 & 0.0075 & 0.0566\\
\addlinespace
Effect & 1 & -0.0194 & -0.0389 & 0.0001\\
Effect & 2 & -0.0265 & -0.0665 & 0.0135\\
Effect & 3 & -0.0331 & -0.0879 & 0.0217\\
Effect & 4 & -0.0407 & -0.1079 & 0.0266\\
Effect & 5 & -0.0496 & -0.1241 & 0.0249\\
\addlinespace
Effect & 6 & -0.0559 & -0.1357 & 0.0238\\
Effect & 7 & -0.0501 & -0.1369 & 0.0366\\
Effect & 8 & -0.0474 & -0.1425 & 0.0476\\
Effect & 9 & -0.0448 & -0.1491 & 0.0595\\
Effect & 10 & -0.0388 & -0.1519 & 0.0744\\
\bottomrule
\end{tabular}
\begin{tablenotes}
\item Estimates from the de Chaisemartin and D'Haultf\oe uille (2020, 2024) estimator with switchers = ``in''. Analytical standard errors clustered at the country level. 67 switchers. Joint test of effects: $p = 0.3878$. Joint test of placebos: $p = 6e-04$.
\end{tablenotes}
\end{threeparttable}
\end{table}

\begin{table}[H]
\centering
\caption{\label{tab:dcdh-out-table}dCDH Estimates: Transitions Out of Democracy}
\centering
\begin{threeparttable}
\begin{tabular}[t]{lrrrr}
\toprule
Type & Period & Estimate & Lower 95\% CI & Upper 95\% CI\\
\midrule
Placebo & -5 & -0.1263 & -0.2835 & 0.0309\\
Placebo & -4 & -0.1394 & -0.2985 & 0.0196\\
Placebo & -3 & -0.1300 & -0.2332 & -0.0268\\
Placebo & -2 & -0.0602 & -0.1077 & -0.0128\\
Placebo & -1 & -0.0255 & -0.0489 & -0.0021\\
\addlinespace
Effect & 1 & 0.0286 & -0.0130 & 0.0702\\
Effect & 2 & 0.0553 & -0.0078 & 0.1185\\
Effect & 3 & 0.0694 & -0.0168 & 0.1557\\
Effect & 4 & 0.0813 & -0.0251 & 0.1878\\
Effect & 5 & 0.0955 & -0.0208 & 0.2118\\
\addlinespace
Effect & 6 & 0.1099 & -0.0113 & 0.2310\\
Effect & 7 & 0.1311 & -0.0078 & 0.2700\\
Effect & 8 & 0.1442 & 0.0051 & 0.2833\\
Effect & 9 & 0.1380 & -0.0050 & 0.2809\\
Effect & 10 & 0.1523 & 0.0007 & 0.3038\\
\bottomrule
\end{tabular}
\begin{tablenotes}
\item Estimates from the de Chaisemartin and D'Haultf\oe uille (2020, 2024) estimator with switchers = ``out''. Analytical standard errors clustered at the country level. 16 switchers. Joint test of effects: $p = 0.0524$. Joint test of placebos: $p = 0.1612$.
\end{tablenotes}
\end{threeparttable}
\end{table}

## 5. Stacked Difference-in-Differences Event Study

I next construct a stacked DID event study as a comparison exercise. For each 
transition event occurring in year \(g\), I define a cohort-specific window of 
\([g-10, g+10]\). The treated unit is the country that experiences the 
transition. The control group consists of countries with no regime switch of any
kind inside that event window. Each sub-experiment is then stacked together, and 
the model is estimated with stack-by-unit and stack-by-year fixed effects.

\medskip\noindent
This design is attractive because it creates transparent comparisons using clean 
controls. At the same time, identification rests on a cohort-specific parallel
trends assumption: absent the transition, treated countries and clean controls 
would have followed parallel trajectories within the event window. Unlike the de 
Chaisemartin and D'Haultfœuille estimator, the stacked design depends directly 
on the chosen window and on the sample restrictions used to define 
uncontaminated controls.

### 5.1 Transitions into Democracy

Figure \ref{fig:stacked-in} shows the stacked DID estimates for transitions 
into democracy. The pre-treatment coefficients are positive and significant 
across the full window ($-10$ to $-2$), confirming the pre-trend pattern 
observed in the main estimator. Post-treatment coefficients are negative and 
statistically significant in the early post-transition years (periods 0 through 
7), with point estimates ranging from $-0.028$ to $-0.061$. The stacked DID 
thus corroborates the dCDH finding that democratization is not followed by 
relative GDP gains in this specification, and that the result is confounded by
pre-existing differential trends.

\begin{figure}[H]
\includegraphics[width=0.9\linewidth]{../task1/output/figures/fig_stacked_in} \caption{Stacked DID Event Study: Transitions Into Democracy}\label{fig:stacked-in}
\end{figure}

### 5.2 Transitions out of Democracy

Figure \ref{fig:stacked-out} shows the stacked DID estimates for transitions 
out of democracy. As with transitions in, the pre-treatment coefficients are 
positive and significant, indicating that countries losing democracy were on 
higher relative GDP paths before the reversal. Post-treatment coefficients are 
negative and significant (periods 0 through 7), with estimates between $-0.036$ 
and $-0.088$. Notably, the stacked DID produces negative post-treatment 
effects for democratic reversals, whereas the dCDH estimator produces positive 
ones. This sign discrepancy is discussed in the comparison section below.

\begin{figure}[H]
\includegraphics[width=0.9\linewidth]{../task1/output/figures/fig_stacked_out} \caption{Stacked DID Event Study: Transitions Out of Democracy}\label{fig:stacked-out}
\end{figure}

\noindent
Tables \ref{tab:stacked-in-table} and \ref{tab:stacked-out-table} present the 
corresponding estimates.

\begin{table}[H]
\centering
\caption{\label{tab:stacked-in-table}Stacked DID Estimates: Transitions Into Democracy}
\centering
\fontsize{9}{11}\selectfont
\begin{threeparttable}
\begin{tabular}[t]{lrrrrr}
\toprule
Type & Period & Estimate & SE & Lower 95\% CI & Upper 95\% CI\\
\midrule
Pre-treatment & -10 & 0.1576 & 0.0403 & 0.0786 & 0.2365\\
Pre-treatment & -9 & 0.1556 & 0.0368 & 0.0836 & 0.2277\\
Pre-treatment & -8 & 0.1315 & 0.0346 & 0.0637 & 0.1993\\
Pre-treatment & -7 & 0.1190 & 0.0297 & 0.0608 & 0.1771\\
Pre-treatment & -6 & 0.1006 & 0.0273 & 0.0470 & 0.1541\\
\addlinespace
Pre-treatment & -5 & 0.0928 & 0.0246 & 0.0447 & 0.1409\\
Pre-treatment & -4 & 0.0731 & 0.0209 & 0.0321 & 0.1141\\
Pre-treatment & -3 & 0.0569 & 0.0155 & 0.0265 & 0.0874\\
Pre-treatment & -2 & 0.0271 & 0.0102 & 0.0072 & 0.0470\\
Pre-treatment & -1 & 0.0000 & 0.0000 & 0.0000 & 0.0000\\
\addlinespace
Treatment & 0 & -0.0280 & 0.0076 & -0.0430 & -0.0130\\
Post-treatment & 1 & -0.0395 & 0.0139 & -0.0668 & -0.0122\\
Post-treatment & 2 & -0.0433 & 0.0176 & -0.0778 & -0.0087\\
Post-treatment & 3 & -0.0473 & 0.0209 & -0.0882 & -0.0065\\
Post-treatment & 4 & -0.0553 & 0.0239 & -0.1021 & -0.0084\\
\addlinespace
Post-treatment & 5 & -0.0595 & 0.0254 & -0.1093 & -0.0096\\
Post-treatment & 6 & -0.0614 & 0.0269 & -0.1141 & -0.0087\\
Post-treatment & 7 & -0.0601 & 0.0290 & -0.1170 & -0.0033\\
Post-treatment & 8 & -0.0581 & 0.0312 & -0.1192 & 0.0030\\
Post-treatment & 9 & -0.0443 & 0.0331 & -0.1092 & 0.0206\\
\addlinespace
Post-treatment & 10 & -0.0355 & 0.0353 & -0.1047 & 0.0336\\
\bottomrule
\end{tabular}
\begin{tablenotes}
\item Stacked DID following Cengiz et al. (2019). Each transition event defines a cohort-specific sub-experiment with event window $[-10, +10]$. Controls have no regime switch of any kind inside the window. Cluster-robust standard errors at the country level. Reference period: $t = -1$.
\end{tablenotes}
\end{threeparttable}
\end{table}

\begin{table}[H]
\centering
\caption{\label{tab:stacked-out-table}Stacked DID Estimates: Transitions Out of Democracy}
\centering
\fontsize{9}{11}\selectfont
\begin{threeparttable}
\begin{tabular}[t]{lrrrrr}
\toprule
Type & Period & Estimate & SE & Lower 95\% CI & Upper 95\% CI\\
\midrule
Pre-treatment & -10 & 0.1631 & 0.0349 & 0.0946 & 0.2315\\
Pre-treatment & -9 & 0.1403 & 0.0317 & 0.0781 & 0.2025\\
Pre-treatment & -8 & 0.1325 & 0.0318 & 0.0701 & 0.1949\\
Pre-treatment & -7 & 0.1193 & 0.0304 & 0.0598 & 0.1789\\
Pre-treatment & -6 & 0.0892 & 0.0312 & 0.0281 & 0.1503\\
\addlinespace
Pre-treatment & -5 & 0.0684 & 0.0280 & 0.0135 & 0.1234\\
Pre-treatment & -4 & 0.0466 & 0.0235 & 0.0006 & 0.0925\\
Pre-treatment & -3 & 0.0340 & 0.0167 & 0.0013 & 0.0667\\
Pre-treatment & -2 & 0.0214 & 0.0105 & 0.0008 & 0.0419\\
Pre-treatment & -1 & 0.0000 & 0.0000 & 0.0000 & 0.0000\\
\addlinespace
Treatment & 0 & -0.0363 & 0.0127 & -0.0611 & -0.0115\\
Post-treatment & 1 & -0.0628 & 0.0189 & -0.0998 & -0.0259\\
Post-treatment & 2 & -0.0720 & 0.0262 & -0.1233 & -0.0207\\
Post-treatment & 3 & -0.0761 & 0.0317 & -0.1382 & -0.0141\\
Post-treatment & 4 & -0.0816 & 0.0354 & -0.1509 & -0.0123\\
\addlinespace
Post-treatment & 5 & -0.0792 & 0.0378 & -0.1533 & -0.0050\\
Post-treatment & 6 & -0.0824 & 0.0417 & -0.1642 & -0.0007\\
Post-treatment & 7 & -0.0876 & 0.0418 & -0.1694 & -0.0057\\
Post-treatment & 8 & -0.0800 & 0.0435 & -0.1652 & 0.0052\\
Post-treatment & 9 & -0.0826 & 0.0483 & -0.1772 & 0.0119\\
\addlinespace
Post-treatment & 10 & -0.0879 & 0.0515 & -0.1888 & 0.0130\\
\bottomrule
\end{tabular}
\begin{tablenotes}
\item Stacked DID following Cengiz et al. (2019). Each transition event defines a cohort-specific sub-experiment with event window $[-10, +10]$. Controls have no regime switch of any kind inside the window. Cluster-robust standard errors at the country level. Reference period: $t = -1$.
\end{tablenotes}
\end{threeparttable}
\end{table}

## 6. Comparing the Two Approaches

The final step is to compare the main dynamic DID estimator with the stacked DID
design. Figures \ref{fig:compare-in} and \ref{fig:compare-out} place the two 
sets of estimates side by side for transitions into and out of democracy, 
respectively.

\begin{figure}[H]
\includegraphics[width=0.9\linewidth]{../task1/output/figures/fig_compare_in} \caption{Transitions Into Democracy: de Chaisemartin and D'Haultfœuille versus Stacked DID}\label{fig:compare-in}
\end{figure}

\begin{figure}[H]
\includegraphics[width=0.9\linewidth]{../task1/output/figures/fig_compare_out} \caption{Transitions Out of Democracy: de Chaisemartin and D'Haultfœuille versus Stacked DID}\label{fig:compare-out}
\end{figure}

\noindent
The comparison between the two estimators reveals both agreement and 
disagreement. For transitions into democracy (Figure \ref{fig:compare-in}), the
two approaches are qualitatively aligned: both show positive pre-trends and 
negative post-treatment coefficients, although the stacked DID estimates are 
more precise and statistically significant in the early post-treatment periods.

\medskip\noindent
For transitions out of democracy (Figure \ref{fig:compare-out}), the two 
estimators disagree on the sign of the post-treatment effects. The dCDH 
estimator shows positive effects (GDP rises after losing democracy), while the 
stacked DID shows negative effects. This discrepancy likely reflects differences
in how the two methods handle pre-existing trends and define comparison groups. 
The dCDH estimator compares switchers to non-switchers with the same baseline 
treatment, adjusting for contemporaneous trends. The stacked DID, by contrast, 
uses only clean controls within a fixed event window, and the strong positive 
pre-trends in the stacked sample may contaminate the post-treatment estimates 
through a continuation of the differential trend. With only 15--16 switchers-out
in the dCDH and a similarly small treated sample in the stacked design, both 
sets of estimates should be interpreted with caution.

\medskip\noindent
The disagreement underscores a broader point: in settings with violated parallel 
trends and non-absorbing treatment, the choice of estimator and comparison group 
materially affects the conclusions. Neither approach can deliver a clean causal
estimate without a credible parallel trends assumption, and the pre-trend 
violations documented here suggest that this assumption is unlikely to hold 
unconditionally.

## 7. Discussion and Limitations

The most important finding of this analysis is that the parallel trends 
assumption is violated for transitions into democracy ($p = 0.0006$ on the 
joint placebo test). Countries that democratize were on declining GDP 
trajectories relative to non-switchers before the transition occurred. This 
pre-existing divergence makes it difficult to attribute the post-treatment GDP 
path causally to the regime change itself.

\medskip\noindent
This pattern is substantively informative even if it prevents clean causal 
identification. It suggests that democratization is partly endogenous to 
economic conditions: countries tend to transition to democracy during periods of
relative economic weakness. This is consistent with the political economy 
literature on the determinants of regime change, which emphasizes the role of 
economic crises in triggering democratic transitions (Acemoglu and Robinson, 
2006; Haggard and Kaufman, 2016).

\medskip\noindent
For transitions out of democracy, the small number of switchers (15--16) limits 
both power and the reliability of pre-trend tests. The dCDH and stacked DID 
estimators disagree on the sign of post-treatment effects, further cautioning 
against strong causal claims.

\medskip\noindent
Relative to the findings of Acemoglu et al. (2019), who report positive 
long-run effects of democracy on GDP, the present analysis uses a shorter panel 
(1970--2010 versus 1960--2010), no covariates, and a different estimator. 
Acemoglu et al. control for lags of GDP and use an instrumental variable 
strategy based on regional democratization waves. These additional controls and 
identification strategies may account for the pre-existing differential trends 
that confound the unconditional event study presented here. The results in this 
report should therefore be read as illustrating the importance of addressing 
pre-trends and endogeneity, rather than as evidence against the democracy-growth
relationship.

\medskip\noindent
Two additional caveats deserve mention. First, the dCDH estimator requires a 
no-carryover assumption: potential outcomes depend only on current treatment 
status, not on the full history of regime changes. This assumption is likely 
restrictive in the present context, since past democratization may have lasting 
effects on institutions, human capital, and investment even after a reversal. 
Second, the stacked DID relies on the availability of clean controls — countries
with no regime change of any kind within the event window — and the composition 
of this control group may differ systematically from the treated countries in 
ways that affect the estimates.

## 8. Conclusion

This report estimates the dynamic effect of democratic transitions on log GDP per
capita using a country-year panel with non-absorbing treatment. The preferred 
estimator is the dynamic DID approach of de Chaisemartin and D'Haultfœuille 
(2020, 2024), with a stacked DID event study as a comparison.

\medskip\noindent
The central finding is that parallel trends is violated for transitions into 
democracy: countries that democratize were already on declining relative GDP 
trajectories before the regime change. Post-treatment effects are negative but 
statistically insignificant. For transitions out of democracy, the evidence is 
mixed, with the two estimators disagreeing on the sign of post-treatment 
effects, and the small number of switchers limiting statistical power.

\medskip\noindent
These results highlight the endogeneity of regime transitions to economic 
conditions and underscore the difficulty of identifying the causal effect of 
democracy on growth without additional controls or instruments. The findings are
consistent with the broader methodological message of the recent DID literature:
in settings with staggered and non-absorbing treatment, estimator choice and 
pre-trend diagnostics are essential for credible inference.

## References

- Acemoglu, D. and Robinson, J.A. (2006). *Economic Origins of Dictatorship and Democracy.* 
Cambridge University Press.
- Acemoglu, D., Naidu, S., Restrepo, P. and Robinson, J.A. (2019). "Democracy 
Does Cause Growth." *Journal of Political Economy*, 127(1), 47–100.
- Callaway, B. and Sant'Anna, P.H.C. (2021). "Difference-in-Differences with 
Multiple Time Periods." *Journal of Econometrics*, 225(2), 200–230.
- Cengiz, D., Dube, A., Lindner, A. and Zipperer, B. (2019). "The Effect of 
Minimum Wages on Low-Wage Jobs." *Quarterly Journal of Economics*, 134(3), 
1405–1454.
- de Chaisemartin, C. and D'Haultfœuille, X. (2020). "Two-Way Fixed Effects 
Estimators with Heterogeneous Treatment Effects." *American Economic Review*, 
110(9), 2964–2996.
- de Chaisemartin, C. and D'Haultfœuille, X. (2024). "Difference-in-Differences 
Estimators of Intertemporal Treatment Effects." 
*Review of Economics and Statistics*, 1–45.
- Gardner, J. (2022). "Two-Stage Differences in Differences." Working Paper.
- Goodman-Bacon, A. (2021). "Difference-in-Differences with Variation in 
Treatment Timing." *Journal of Econometrics*, 225(2), 254–277.
- Haggard, S. and Kaufman, R.R. (2016). *Dictators and Democrats: Masses, 
Elites, and Regime Change.* Princeton University Press.
- Roth, J., Sant'Anna, P.H.C., Bilinski, A. and Poe, J. (2023). "What's Trending 
in Difference-in-Differences?" *Journal of Econometrics*, 235, 2218–2244.
- Sun, L. and Abraham, S. (2021). "Estimating Dynamic Treatment Effects in Event 
Studies with Heterogeneous Treatment Effects." *Journal of Econometrics*, 225(2), 
175–199.

\newpage

# Task 2 — Data Audit Plan for Historical Elections Data

## 1. Audit Strategy

The objective of this audit is to assess the internal consistency and 
reliability of a municipality-election dataset digitized via OCR from 
historical paper records. Given the nature of OCR-generated data, errors may 
range from minor formatting inconsistencies to substantive misreporting of 
numeric values. The audit strategy therefore prioritizes checks according to 
their potential impact on data validity.

\medskip\noindent
The first priority is to identify logical impossibilities and accounting 
inconsistencies. These include cases where the number of voters exceeds the 
number of registered electors, mismatches between total valid votes and the sum 
of party-level votes, inconsistencies involving invalid and blank ballots, and 
discrepancies between total council seats and their allocation across parties. 
These checks are essential because they identify observations that cannot be 
internally reconciled and therefore compromise the integrity of the dataset.

\medskip\noindent
The second priority is to identify duplication and geographic inconsistencies. 
Because the dataset spans multiple elections across municipalities, the relevant 
unit of observation is the municipality-election pair. The audit therefore 
checks for exact and near-duplicate records, as well as inconsistencies between 
municipality names and standardized municipality codes. These issues affect the 
uniqueness and comparability of observations.

\medskip\noindent
The final priority is to identify OCR-related formatting issues and structural 
missingness. These include capitalization inconsistencies, irregular spacing, 
and missing values in ballot-detail variables. While these issues are typically 
less consequential for inference, they are important for data harmonization and 
reproducibility.

\medskip\noindent
Automatic corrections are restricted to formatting issues that can be addressed 
mechanically with high confidence. All discrepancies involving numeric values, 
accounting identities, duplication, or geographic identifiers are flagged for 
manual review.

## 2. Implemented Audit Checks

The audit is implemented as a reproducible pipeline that reads the raw dataset, 
applies a sequence of validation checks, and records all flagged issues in a 
structured audit log. Each check is defined programmatically and contributes one 
or more entries to the audit log, which includes the row identifier, the audit 
category, the specific check performed, a severity classification, and a 
recommended action.

\medskip\noindent
The implemented checks cover five main dimensions. First, vote-logic checks 
verify whether turnout exceeds the number of registered electors and whether 
turnout rates are implausibly extreme. Second, vote-accounting checks compare 
reported totals with the sum of component vote variables. Third, seat-accounting 
checks compare total seats with the sum of party seat allocations. Fourth, 
duplication and geographic checks identify exact and near-duplicate records and 
mismatches between municipality names and standardized codes. Fifth, 
OCR-formatting checks detect capitalization, spacing, and name standardization 
issues.

\medskip\noindent
All checks are implemented using a consistent structure: each validation rule 
filters problematic observations and appends them to a unified audit log with 
standardized fields. This ensures that the audit process is fully reproducible 
and that all issues are tracked in a transparent manner. The same logic is 
applied across all audit dimensions, and the resulting audit log is exported as 
a structured file for validation and documentation.

## 3. Issue Types and Proposed Actions

Each identified issue is associated with a recommended treatment based on its 
severity and the degree of ambiguity involved. Logical impossibilities, such as 
cases where turnout exceeds the number of registered electors, are classified as 
critical and flagged for immediate manual review. These cases indicate either 
OCR errors in key numeric fields or inconsistencies in the original records and 
cannot be corrected automatically without external validation.

\medskip\noindent
High-severity issues include vote-accounting mismatches, seat-accounting 
inconsistencies, and near-duplicate observations. These issues may reflect 
misalignment between totals and their components, duplication of records, or 
partial transcription errors. Given their potential impact on empirical analysis, 
they are systematically flagged for manual inspection and correction.

\medskip\noindent
Medium-severity issues include inconsistencies between municipality names and 
standardized municipality codes, as well as missing totals that prevent internal 
validation. These issues are often ambiguous: they may arise from OCR errors, 
administrative changes in municipality identifiers, or incomplete records. As a 
result, they require cross-validation with external sources or historical 
documentation before any correction is applied.

\medskip\noindent
Low-severity issues are primarily related to formatting inconsistencies and OCR 
noise. These include capitalization errors, irregular spacing, and minor 
variations in municipality names. Such issues can be corrected automatically with 
high confidence using standardized string-cleaning procedures, provided that the 
original values are preserved for traceability. Structural missingness in 
ballot-detail variables is treated as a documented feature of the dataset rather 
than an error, and coding conventions are recorded but not altered.

## 4. Structured Audit Output

The audit produces a structured output file that records all identified issues 
at the observation level. Each entry corresponds to a specific validation failure 
and includes a unique row identifier, the audit category, the name of the check, 
a severity classification, and a recommended action.

\medskip\noindent
This structure ensures that the audit process is transparent, reproducible, and 
easily interpretable. By separating detection from correction, the approach 
allows for systematic validation of flagged observations before any modification 
is made to the dataset. Recommended actions are standardized into categories such 
as \texttt{manual\_review}, \texttt{manual\_review\_name}, 
\texttt{auto\_correct}, and \texttt{note}, which facilitates downstream 
processing and documentation.

## 5. Audit Results

The audit identifies a total of 781 flags across 577 observations, indicating 
that each observation is flagged at least once. This high coverage is largely 
driven by low-severity issues, particularly structural missingness in 
ballot-detail variables and coding conventions related to invalid and blank 
ballots.

\begin{table}[H]
\centering
\caption{\label{tab:audit-overview}Audit Overview}
\centering
\begin{tabular}[t]{lr}
\toprule
Metric & Value\\
\midrule
Total flags & 781\\
Unique rows flagged & 577\\
Total rows in dataset & 577\\
\bottomrule
\end{tabular}
\end{table}

\noindent
Critical inconsistencies are rare, with only a small number of cases where the 
number of voters exceeds the number of registered electors. High-severity issues 
are concentrated in vote-accounting mismatches, seat-accounting inconsistencies, 
and near-duplicate observations. Medium-severity issues are primarily associated 
with municipality-name and municipality-code mismatches and missing totals that 
limit internal validation.

\medskip\noindent
Low-severity issues account for the majority of flags and are largely cosmetic or 
structural in nature. These findings suggest that while the dataset contains 
systematic OCR-related noise, the most consequential inconsistencies are limited 
to a relatively small subset of observations.

\begin{table}[H]
\centering
\caption{\label{tab:audit-summary}Data Audit Summary: Flagged Issues by Category and Severity}
\centering
\resizebox{\ifdim\width>\linewidth\linewidth\else\width\fi}{!}{
\begin{threeparttable}
\begin{tabular}[t]{llllr}
\toprule
Category & Check & Severity & Action & N\\
\midrule
Vote\_logic & votanti\_gt\_elettori & critical & manual\_review & 2\\
Duplicates & near\_duplicate & high & manual\_review & 10\\
Seat\_accounting & seat\_total\_mismatch & high & manual\_review & 7\\
Vote\_accounting & vote\_total\_mismatch & high & manual\_review & 30\\
Vote\_accounting & listvote\_total\_mismatch & high & manual\_review & 9\\
\addlinespace
Geography & province\_code\_mismatch & medium & manual\_review & 2\\
Missing & missing\_totals & medium & manual\_review & 21\\
OCR\_name & name\_code\_mismatch & medium & manual\_review\_name & 77\\
Vote\_logic & extreme\_turnout & medium & manual\_review & 3\\
Missing & structural\_na\_ballot\_detail & low & note\_structural\_missing & 442\\
\addlinespace
OCR\_name & preposition\_capitalization & low & auto\_correct\_prepositions & 46\\
OCR\_name & all\_caps\_comune & low & auto\_correct\_to\_title\_case & 26\\
OCR\_name & spurious\_spaces & low & auto\_correct\_merge\_words & 1\\
Vote\_accounting & schede\_bianche\_in\_invalidi & low & note\_coding\_convention & 105\\
\bottomrule
\end{tabular}
\begin{tablenotes}
\item Severity levels: critical (logically impossible values), high (accounting identity failures or duplicates), medium (plausible but suspicious values requiring review), low (cosmetic or structural issues correctable automatically). N = number of flagged observations per check.
\end{tablenotes}
\end{threeparttable}}
\end{table}

## 6. Conclusion

The proposed audit strategy provides a structured and reproducible framework for 
assessing the quality of OCR-derived historical election data. By prioritizing 
logical and accounting consistency, distinguishing between levels of severity, 
and clearly separating automatic corrections from manual review, the approach 
ensures both rigor and transparency.

\medskip\noindent
The resulting audit log serves as a comprehensive diagnostic tool, enabling 
targeted data cleaning while preserving the integrity of the original dataset. 
Overall, the dataset is suitable for empirical analysis, provided that the 
identified high- and critical-severity issues are addressed through careful 
validation.
