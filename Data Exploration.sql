SELECT *
FROM CovidDeaths
WHERE location = 'Philippines'
SELECT* FROM CovidVaccinations
WHERE location = 'Philippines'

--TOTAL NUMBER OF DEATHS PER DAY IN THE PHILIPPINES
SELECT date, continent, location, total_deaths
FROM PortfolioProject..CovidDeaths
WHERE continent is not null and total_deaths is not null and location = 'Philippines' 


--TOTAL CASES VS POPULATION
--Likelihood of getting infected
SELECT date, continent, location, population, total_cases, (total_cases/population)*100 as CasePercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL and location = 'Philippines'

--TOTAL CASES VS TOTAL DEATH 
--Likelihood of dying if you contract covid in your country
SELECT date, continent, location, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentageOverCases
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 


--HIGHEST LOCATION INFECTED
SELECT continent, location, population, max(total_cases) as HighestInfectionCount, MAX((total_cases/population)*100) as HighestCasePercentage
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, location, population
order by HighestCasePercentage desc

--NEW CASES AND DEATHS BEFORE BOOSTERS AROUND THE WORLD
SELECT CovidDeaths.continent, CovidDeaths.location, CovidDeaths.date, new_cases, total_deaths, CovidVaccinations.total_boosters
FROM CovidDeaths
INNER JOIN CovidVaccinations
ON CovidDeaths.location = CovidVaccinations.location
WHERE total_boosters is NULL AND CovidDeaths.location = 'Albania'
ORDER BY location

--NEW CASES AND DEATHS AFTER BOOSTERS AROUND THE WORLD
SELECT CovidDeaths.continent, CovidDeaths.location, CovidDeaths.date, new_cases, total_deaths, CovidVaccinations.total_boosters
FROM CovidDeaths
INNER JOIN CovidVaccinations
ON CovidDeaths.location = CovidVaccinations.location
WHERE CovidDeaths.continent IS NOT NULL AND total_boosters IS NOT NULL AND CovidDeaths.location = 'Albania'
ORDER BY location

--LOCATION WITH HIGHEST DEATHCOUNT
SELECT continent, location, population, max(total_cases) as HighestInfectionCount, MAX(CAST(total_deaths AS int)) as HighestDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, location, population
order by HighestDeathCount desc

-- CONTINENT DEATH PERCENTAGE OVER CASES
With TotalDeaths_CTE (Continent, TotalCases, TotalDeaths) as 
(
SELECT continent, max(total_cases) as TotalCases ,max(cast(total_deaths as int)) as TotalDeaths
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
group by continent
)
SELECT *, (TotalDeaths/TotalCases)*100 as Death_Percentage_Per_Continent
FROM TotalDeaths_CTE
ORDER BY Continent


-- WORLD DEATH RATE DAILY

SELECT date, SUM(new_cases) as Total_Cases, SUM(CAST(new_deaths as int)) as Total_Deaths,  SUM(CAST(new_deaths as int)) / SUM(new_cases) *100 as Death_Percentage_Per_Day
FROM CovidDeaths
WHERE continent is not null
group by date
ORDER BY date

-- TOTAL POPULATION VS TOTAL VACCINATION

SELECT Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Vaxx.new_vaccinations,
SUM(Cast(Vaxx.new_vaccinations as bigint)) OVER (PARTITION BY Deaths.location order by Deaths.date) as Total_vaccinations_per_day
FROM CovidDeaths as Deaths
JOIN CovidVaccinations as Vaxx
ON Deaths.location = Vaxx.location
and Deaths.date = Vaxx.date
WHERE Deaths.continent IS NOT NULL
ORDER BY location, date

--TEMP TABLE
DROP TABLE IF EXISTS #VaccinationPercentage
CREATE TABLE #VaccinationPercentage (
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
Total_Vaccinations_Per_Day numeric
)

INSERT INTO #VaccinationPercentage
SELECT Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Vaxx.new_vaccinations,
SUM(Cast(Vaxx.new_vaccinations as bigint)) OVER (PARTITION BY Deaths.location order by Deaths.date) as Total_vaccinations_per_day
FROM CovidDeaths as Deaths
JOIN CovidVaccinations as Vaxx
ON Deaths.location = Vaxx.location
and Deaths.date = Vaxx.date
WHERE Deaths.continent IS NOT NULL

SELECT*, (Total_Vaccinations_Per_Day/Population)*100 AS Vaccination_Percentage
FROM #VaccinationPercentage


--VIEWS FOR VISUALIZATION

CREATE VIEW Death_Percentage_Per_Cases as
SELECT date, continent, location, total_cases, total_deaths, (total_deaths/total_cases)*100 as Death_Percentage_Per_Cases
FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL 

CREATE VIEW Death_Percentage_Per_Continent as
With TotalDeaths_CTE (Continent, TotalCases, TotalDeaths) as 
(
SELECT continent, max(total_cases) as TotalCases ,max(cast(total_deaths as int)) as TotalDeaths
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
group by continent
)
SELECT *, (TotalDeaths/TotalCases)*100 as Death_Percentage_Per_Continent
FROM TotalDeaths_CTE

CREATE VIEW Death_Percentage_Per_Day as
SELECT date, SUM(new_cases) as Total_Cases, SUM(CAST(new_deaths as int)) as Total_Deaths,  SUM(CAST(new_deaths as int)) / SUM(new_cases) *100 as Death_Percentage_Per_Day
FROM CovidDeaths
WHERE continent is not null
group by date

CREATE VIEW Total_Vaccinations_Per_Day as
SELECT Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Vaxx.new_vaccinations,
SUM(Cast(Vaxx.new_vaccinations as bigint)) OVER (PARTITION BY Deaths.location order by Deaths.date) as Total_vaccinations_per_day
FROM CovidDeaths as Deaths
JOIN CovidVaccinations as Vaxx
ON Deaths.location = Vaxx.location	
and Deaths.date = Vaxx.date
WHERE Deaths.continent IS NOT NULL


