# Doelen dashboard

1. Shits 'n giggles
2. Evidence.dev uitproberen
3. Inzicht houden in mijn inkomsten & uren voor werk
4. Vroegtijd signaleren van fouten

# Bronnen:

- Loonstrookjes (financial.csv in Hours dir) - manuele invoer o.b.v. pdfs uit NMBRS app
- Hours (TimeChimp export naar csv) - manuele actie voor export. 

Deze bronnen worden opgeschoond en gejoined tot One Big Table (OBT) in Inkomsten.R in Hours/code directory

# Dashboard Data:

Het evidence.dev dashboard gebruikt de OBT op verschillende manieren:

- fin_data_wide -> is de een-op-een kopie van de OBT
- fin_data_long -> OBT, maar dan long op jaar, maand, datum, kolomnaam uit OBT en bijbehorende waarde (nodig voor gestapelde bar graphs)

# Dashboard Design:

Design moet direct gekoppeld zijn aan mijn doelen van het dashboard:
- .md en html syntax snappen, managen van data sources en begrijpen van de documentatie
- parameterisering van dashboard, zodat je makkelijk kan filteren en aggregeren
- spelen met grafiektypen voor beste inzicht/visualisering
- Layout & Shading 
- Storytelling, kan ik met het design ook een goed verhaal vertellen?

# Verdere ontwikkeling:

1. ~~Automatisering van data pipeline? Lijkt lastig, want afhankelijk van manuele acties. Maar tussenstap kan zijn om data in sqlite/duckdb te stoppen~~
2. ~~Dashboard design:~~
	~~betere visuals: layout, paginering, kleurstelling en grafiektype-keuzen~~
	~~betere as-titels: uniformiteit en juiste niveau~~
3. ~~Datatype management: bv. jaar en ym kolommen ziet evidence.dev als numbers, terwijl ik ze strings wil laten zijn. Hoe pas ik dit aan?~~
4. Customization: evidence logo eruit slopen
5. Aanpassing index.md: 
	- Alert Status met meta gegevens onderaan de pagina
	- Meta gegevens uitbreiden met laatste update datum van de data
6. Betere opties om te filteren ipv een dropdown. Ik kan kiezen uit checkbox en date range.

# Evidence Template Project

## Using Codespaces

If you are using this template in Codespaces, click the `Start Evidence` button in the bottom status bar. This will install dependencies and open a preview of your project in your browser - you should get a popup prompting you to open in browser.

Or you can use the following commands to get started:

```bash
npm install
npm run sources
npm run dev -- --host 0.0.0.0
```

See [the CLI docs](https://docs.evidence.dev/cli/) for more command information.

**Note:** Codespaces is much faster on the Desktop app. After the Codespace has booted, select the hamburger menu → Open in VS Code Desktop.

## Get Started from VS Code

The easiest way to get started is using the [VS Code Extension](https://marketplace.visualstudio.com/items?itemName=Evidence.evidence-vscode):



1. Install the extension from the VS Code Marketplace
2. Open the Command Palette (Ctrl/Cmd + Shift + P) and enter `Evidence: New Evidence Project`
3. Click `Start Evidence` in the bottom status bar

## Get Started using the CLI

```bash
npx degit evidence-dev/template my-project
cd my-project 
npm install 
npm run sources
npm run dev 
```

Check out the docs for [alternative install methods](https://docs.evidence.dev/getting-started/install-evidence) including Docker, Github Codespaces, and alongside dbt.

## Learning More

- [Docs](https://docs.evidence.dev/)
- [Github](https://github.com/evidence-dev/evidence)
- [Slack Community](https://slack.evidence.dev/)
- [Evidence Home Page](https://www.evidence.dev)
