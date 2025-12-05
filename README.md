# 2025-mlb-contract-efficiency
# **MLB Contract Efficiency Analysis – 2025 Season**
### *A full R-based exploration of WAR, salary, and team/position value across Major League Baseball*

This project evaluates **contract efficiency across MLB in 2025** by combining Opening Day salaries from Cot's baseball contracts on legacy baseball prospectus website with FanGraphs WAR.  

I built this project to demonstrate:
- My ability to work with real baseball datasets  
- My coding skills in R (tidyverse, ggplot2, ggrepel, janitor)  
- Clear communication of analytical findings  
- A deep understanding of baseball value and roster construction  

---

## ⚾ **Motivation**
Players are making millions of dollars in todays era of baseball but who is worth paying that money? Who deserves more of it?

### **“Which players, teams, and positions provide the most WAR per dollar spent?”**

Using Opening Day contract information and WAR contributions, we break the league into multiple value layers:
- **Positional efficiency**
- **Team value efficiency**
- **Individual surplus value**
- **Player salary vs performance distribution**

---

# 📊 **Key Visuals**

All generated charts are stored in the `outputs/` folder.

### **📌 Positional Contract Efficiency ($/WAR)**
Lower = better. Utility players offered surprising surplus value.


---

### **📌 Salary vs WAR (with median quadrant lines + labeled outliers)**
Shows where performance meets dollar investment.
![Salary vs WAR](outputs/2025_salary_vs_war_by_position.png)

---

### **📌 Team Contract Efficiency — Rockies removed as extreme outlier**
Green = best value, Red = worst value.
![Team Efficiency Trimmed](outputs/2025_team_dollars_per_war_trimmed.png)

---

### **📌 Top 20 Contract Values (Best $/WAR of 2025)**
![Top 20 Value Contracts](outputs/2025_top20_value_contracts.png)

---

# 🧠 **Key Findings**

### **1. Positional Value**
- **Best value:**  
  Utility roles (INF, OF), CF  
- **Worst value:**  
  RF, DH, 1B — largely due to aging or power-only profiles

---

### **2. Team Efficiency (Rockies removed)**  
- **Best team contract value:**  
  **Miami, Tampa Bay, Milwaukee**
- **Worst team value:**  
  **Los Angeles Angels, Texas Rangers, New York Mets**

---

### **3. Player-Level Surplus Value**
The most efficient contracts in MLB (highest WAR per dollar) included:  
**Tyler Soderstrom, Michael Busch, Masyn Winn, Bryan Woo, Jacob Wilson**, and more.

---

# 🛠️ **Methodology**

### **Data Cleaning**
- Normalized player names across two datasets  
- Standardized positions and created “utility” grouping  
- Cleaned salary formats and parsed numeric values  
- Filled missing teams manually for accurate analysis  

---

### **Handling Multi-Position Players**
If a player was listed at multiple positions (e.g., “2B/SS”):
- **WAR and salary were split evenly across positions**  
This allows accurate positional aggregation.

---

### **Team-Level Outlier Treatment**
- The Colorado Rockies produced values so extreme that they distorted all league comparisons  
- For trimmed visualizations, COL was removed to preserve meaningful comparisons  

---

### **Metrics Used**
- **$ / WAR** — primary contract efficiency metric  
- **WAR per $1M** — inverse efficiency for clarity  
- **Median salary & WAR split quadrants** — for scatter interpretation  
- **Positional aggregates** — share-split performance  

---

# 📁 **Project Structure**

