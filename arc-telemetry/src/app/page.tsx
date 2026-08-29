"use client";

import React, { useState } from "react";
import { 
  Activity, 
  AlertCircle, 
  ArrowUpDown, 
  Cpu, 
  Database, 
  Download, 
  ExternalLink, 
  Play, 
  ShieldAlert, 
  ShieldCheck, 
  TrendingDown, 
  TrendingUp, 
  Zap 
} from "lucide-react";
import { 
  ResponsiveContainer, 
  PieChart, 
  Pie, 
  Cell, 
  LineChart, 
  Line, 
  XAxis, 
  YAxis, 
  Tooltip, 
  CartesianGrid 
} from "recharts";

// Interface Definitions
interface AnomalyLog {
  id: string;
  system: string;
  sector: string;
  severity: "Low" | "Medium" | "High" | "Critical";
  impactScore: number;
  loggedAt: string;
  output: string;
  recommendation: string;
}

interface TestRun {
  id: string;
  engineer: string;
  metricLabel: string;
  metricValue: string;
  stressFactor: string;
}

interface FailurePrediction {
  component: string;
  probability: number;
  timeToFailure: string;
  recommendedAction: string;
}

export default function Home() {
  // --- STATE MANAGEMENT ---
  const [activeSector, setActiveSector] = useState<"Sector 7" | "Sector 3" | "All Sectors">("Sector 7");
  const [selectedLogId, setSelectedLogId] = useState<string>("ERR-8092");
  const [tableSortConfig, setTableSortConfig] = useState<{ key: string; direction: "asc" | "desc" } | null>(null);
  
  // Simulation states
  const [isSimulating, setIsSimulating] = useState(false);
  const [simulationProgress, setSimulationProgress] = useState(0);
  const [predictionResult, setPredictionResult] = useState<FailurePrediction | null>(null);

  // --- MOCK DATA ---
  const sectorData = {
    "Sector 7": {
      fieldFlux: "-9.81 m/s²",
      fieldFluxSub: "Complete 1G Negation",
      fluxStatus: "stable",
      fluxTrend: "stable",
      stability: "98.4%",
      powerDraw: "4.2 TW",
      powerTrend: "elevated",
      massYield: "1.4 kg/s",
      activeNodes: 480
    },
    "Sector 3": {
      fieldFlux: "-6.15 m/s²",
      fieldFluxSub: "63% Gravitational Negation",
      fluxStatus: "fluctuating",
      fluxTrend: "down",
      stability: "82.1%",
      powerDraw: "3.1 TW",
      powerTrend: "stable",
      massYield: "0.8 kg/s",
      activeNodes: 320
    },
    "All Sectors": {
      fieldFlux: "-8.95 m/s²",
      fieldFluxSub: "System-Wide Average Negation",
      fluxStatus: "optimal",
      fluxTrend: "up",
      stability: "92.3%",
      powerDraw: "7.3 TW",
      powerTrend: "elevated",
      massYield: "2.2 kg/s",
      activeNodes: 800
    }
  };

  const selectedSectorInfo = sectorData[activeSector];

  // Recharts Data: Power allocation donut chart
  const energyDistributionData = [
    { name: "Graviton Generation", value: 51, color: "#06b6d4" }, // Cyan
    { name: "Containment Field", value: 31, color: "#a855f7" },    // Purple
    { name: "Cooling Systems", value: 18, color: "#f59e0b" }       // Amber
  ];

  // Recharts Data: Gravitational wave stability over time
  const fieldStabilityData = [
    { time: "00:00", gForce: 0.05, baseline: 0 },
    { time: "05:00", gForce: -0.02, baseline: 0 },
    { time: "10:00", gForce: 0.12, baseline: 0 },
    { time: "15:00", gForce: 0.85, baseline: 0 }, // Spike (Amber zone)
    { time: "20:00", gForce: -0.05, baseline: 0 },
    { time: "25:00", gForce: 0.01, baseline: 0 },
    { time: "30:00", gForce: 0.03, baseline: 0 },
    { time: "35:00", gForce: -0.92, baseline: 0 }, // Critical drop
    { time: "40:00", gForce: -0.05, baseline: 0 }
  ];

  // Data Table: Anti-gravity Generators
  const initialTableData = [
    { component: "Quantum Gyroscope", uptime: 120, temp: 4, output: 12000, status: "Optimal" },
    { component: "Flux Capacitor", uptime: 98, temp: 8, output: 11500, status: "Stable" },
    { component: "Tachyon Manifold", uptime: 45, temp: 12, output: 8000, status: "Warning" },
    { component: "Baryonic Dampener", uptime: 12, temp: 450, output: 2000, status: "Critical" }
  ];

  const [tableData, setTableData] = useState(initialTableData);

  // Sorting Handler
  const handleSort = (key: "component" | "uptime" | "temp" | "output" | "status") => {
    let direction: "asc" | "desc" = "asc";
    if (tableSortConfig && tableSortConfig.key === key && tableSortConfig.direction === "asc") {
      direction = "desc";
    }

    const sortedData = [...tableData].sort((a, b) => {
      let valA = a[key];
      let valB = b[key];

      if (typeof valA === "string") {
        return direction === "asc" ? valA.localeCompare(valB as string) : (valB as string).localeCompare(valA);
      } else {
        return direction === "asc" ? (valA as number) - (valB as number) : (valB as number) - (valA as number);
      }
    });

    setTableData(sortedData);
    setTableSortConfig({ key, direction });
  };

  // Diagnostics Anomaly Logs
  const anomalyLogs: AnomalyLog[] = [
    {
      id: "ERR-8092",
      system: "Baryonic Dampener",
      sector: "Bay 4",
      severity: "High",
      impactScore: 8.5,
      loggedAt: "August 29, 2026",
      output: "Warning: Spontaneous gravity well forming in quadrant 4. Mass negation failing.",
      recommendation: "Flagged for immediate maintenance — primary issue: Coolant leak causing thermal expansion in the graviton matrix. Isolate the sector."
    },
    {
      id: "WARN-2910",
      system: "Flux Capacitor",
      sector: "Bay 2",
      severity: "Medium",
      impactScore: 5.2,
      loggedAt: "August 29, 2026",
      output: "Temporal variance detected. Chrono-stabilization coils operating outside normal bounds.",
      recommendation: "Re-calibrate magnetic shielding in the secondary containment zone."
    },
    {
      id: "ERR-1102",
      system: "Quantum Gyroscope",
      sector: "Ring 1",
      severity: "Critical",
      impactScore: 9.8,
      loggedAt: "August 28, 2026",
      output: "Gyroscope spin axis lock failing. Extreme precession observed in gravitational field vector.",
      recommendation: "Deploy emergency plasma brakes to prevent mechanical disintegration."
    },
    {
      id: "WARN-0988",
      system: "Tachyon Manifold",
      sector: "Sub-rig C",
      severity: "Low",
      impactScore: 3.1,
      loggedAt: "August 28, 2026",
      output: "Minor signal refraction. Tachyon velocity dropping below superluminal threshold.",
      recommendation: "Vent excess exhaust gas from the secondary cooling array."
    }
  ];

  const selectedLog = anomalyLogs.find(log => log.id === selectedLogId) || anomalyLogs[0];

  // Extremes Mock Data
  const peakTolerances: TestRun[] = [
    { id: "RUN-9981", engineer: "Dr. Aris Thorne", metricLabel: "Max Lift Capacity", metricValue: "12.8 Tons", stressFactor: "0.02%" },
    { id: "RUN-8842", engineer: "Dr. Sunita Iyer", metricLabel: "Max Lift Capacity", metricValue: "9.4 Tons", stressFactor: "0.01%" },
    { id: "RUN-7719", engineer: "Prof. Arun Das", metricLabel: "Max Lift Capacity", metricValue: "8.7 Tons", stressFactor: "0.05%" }
  ];

  const catastrophicFailures: TestRun[] = [
    { id: "RUN-1044", engineer: "Prof. Sam Okafor", metricLabel: "Point of Collapse", metricValue: "Containment Breach (Bay 4)", stressFactor: "Instantaneous" },
    { id: "RUN-2291", engineer: "Dr. Ada Reyes", metricLabel: "Point of Collapse", metricValue: "Cooling Valve Blowout", stressFactor: "1.2s delay" },
    { id: "RUN-0912", engineer: "Prof. Vikas Rao", metricLabel: "Point of Collapse", metricValue: "Gyroscope Bearing Failure", stressFactor: "Structural collapse" }
  ];

  // Run Simulation Handler
  const triggerSimulation = () => {
    setIsSimulating(true);
    setPredictionResult(null);
    setSimulationProgress(0);
    
    const interval = setInterval(() => {
      setSimulationProgress((prev) => {
        if (prev >= 100) {
          clearInterval(interval);
          setIsSimulating(false);
          // Show simulated failure prediction result
          setPredictionResult({
            component: "Tachyon Manifold",
            probability: 87.4,
            timeToFailure: "14 hours 22 minutes",
            recommendedAction: "Purge hyper-dimensional coolant valves and isolate primary coil output."
          });
          return 100;
        }
        return prev + 10;
      });
    }, 150);
  };

  return (
    <div className="bg-[#02040a] min-h-screen text-slate-100 flex flex-col items-center py-8 px-4 sm:px-6 lg:px-8">
      <div className="w-full max-w-7xl flex flex-col gap-6 animate-fade-slide">
        
        {/* ==========================================
            1. HEADER SECTION
           ========================================== */}
        <header className="flex flex-col md:flex-row md:items-center md:justify-between border border-zinc-800 bg-zinc-950 p-6 rounded-xl glow-cyan-pulse">
          <div className="flex items-center gap-4">
            <div className="sentio-logo-box text-cyan-400">
              <Cpu className="w-6 h-6 animate-pulse" />
            </div>
            <div>
              <h1 className="font-mono text-xl md:text-2xl font-bold tracking-wider text-white">
                A.R.C. PROPULSION TELEMETRY
              </h1>
              <p className="text-xs text-slate-400 font-medium tracking-wide">
                Project Icarus · Phase 4 Testing · Live Feed
              </p>
            </div>
          </div>
          
          <div className="flex flex-wrap items-center gap-3 mt-4 md:mt-0">
            {/* Clickable Sector Selector Badges */}
            <div className="flex bg-zinc-900 border border-zinc-800 rounded-lg p-1">
              {(["All Sectors", "Sector 7", "Sector 3"] as const).map((sec) => (
                <button
                  key={sec}
                  onClick={() => setActiveSector(sec)}
                  className={`text-xs px-3 py-1.5 rounded-md font-semibold transition-all ${
                    activeSector === sec 
                      ? "bg-zinc-800 text-white border-b-2 border-cyan-500 shadow-sm" 
                      : "text-slate-400 hover:text-slate-200"
                  }`}
                >
                  {sec}
                </button>
              ))}
            </div>
            
            {/* Live Diagnostics Pulse Badge */}
            <div className="flex items-center gap-2 bg-zinc-900 border border-cyan-500/30 rounded-lg px-3 py-1.5">
              <span className="relative flex h-2 w-2">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-cyan-400 opacity-75"></span>
                <span className="relative inline-flex rounded-full h-2 w-2 bg-cyan-500"></span>
              </span>
              <span className="text-[10px] uppercase font-bold text-cyan-400 tracking-wider">
                Live Diagnostics
              </span>
            </div>
            
            <button className="flex items-center justify-center p-2 rounded-lg bg-zinc-900 border border-zinc-800 hover:border-zinc-700 text-slate-400 hover:text-white transition-all">
              <Download className="w-4 h-4" />
            </button>
          </div>
        </header>

        {/* Dynamic Viewing Status Bar */}
        <div className="text-xs text-slate-400 font-mono tracking-wide px-2">
          Viewing: <span className="text-cyan-400 font-semibold">{activeSector}</span> · All Test Rigs · <span className="text-cyan-400 font-semibold">{selectedSectorInfo.activeNodes} Active Nodes</span>
        </div>

        {/* ==========================================
            2. CORE TELEMETRY CARDS (GRID OF 4)
           ========================================== */}
        <section className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          
          {/* Card 1: Local Field Flux */}
          <div className="bg-zinc-950 border border-zinc-800 hover:border-cyan-500/50 rounded-xl p-5 transition-all flex flex-col justify-between h-[140px] shadow-lg group">
            <div className="flex justify-between items-start text-xs text-slate-400 font-semibold tracking-wide">
              <span>LOCAL FIELD FLUX</span>
              <Activity className="w-4 h-4 text-cyan-500" />
            </div>
            <div>
              <div className="font-mono text-2xl font-bold text-white tracking-tight">
                {selectedSectorInfo.fieldFlux}
              </div>
              <p className="text-[11px] text-slate-400 mt-1">
                {selectedSectorInfo.fieldFluxSub}
              </p>
            </div>
            <div className="flex items-center gap-1.5 mt-2">
              <div className="flex gap-1 h-3 items-end">
                <span className="w-[3px] h-[6px] bg-cyan-500/40 rounded-sm"></span>
                <span className="w-[3px] h-[8px] bg-cyan-500/60 rounded-sm"></span>
                <span className="w-[3px] h-[10px] bg-cyan-500/80 rounded-sm"></span>
                <span className="w-[3px] h-[12px] bg-cyan-500 rounded-sm animate-pulse"></span>
              </div>
              <span className="text-[10px] text-cyan-400 font-bold uppercase tracking-wider">
                Stable Negation
              </span>
            </div>
          </div>

          {/* Card 2: Core Stability */}
          <div className="bg-zinc-950 border border-zinc-800 hover:border-purple-500/50 rounded-xl p-5 transition-all flex flex-col justify-between h-[140px] shadow-lg group">
            <div className="flex justify-between items-start text-xs text-slate-400 font-semibold tracking-wide">
              <span>CORE STABILITY</span>
              <ShieldCheck className="w-4 h-4 text-purple-500" />
            </div>
            <div>
              <div className="font-mono text-2xl font-bold text-white tracking-tight">
                {selectedSectorInfo.stability}
              </div>
              <p className="text-[11px] text-slate-400 mt-1">
                Optimal containment field
              </p>
            </div>
            <div className="w-full mt-2">
              <div className="sentio-progress-bg bg-zinc-900">
                <div 
                  className="sentio-progress-bar bg-purple-500 shadow-[0_0_8px_rgba(168,85,247,0.5)] transition-all duration-500" 
                  style={{ width: selectedSectorInfo.stability }}
                ></div>
              </div>
            </div>
          </div>

          {/* Card 3: Power Draw */}
          <div className="bg-zinc-950 border border-zinc-800 hover:border-amber-500/50 rounded-xl p-5 transition-all flex flex-col justify-between h-[140px] shadow-lg group">
            <div className="flex justify-between items-start text-xs text-slate-400 font-semibold tracking-wide">
              <span>POWER DRAW</span>
              <Zap className="w-4 h-4 text-amber-500" />
            </div>
            <div>
              <div className="font-mono text-2xl font-bold text-white tracking-tight">
                {selectedSectorInfo.powerDraw}
              </div>
              <p className="text-[11px] text-slate-400 mt-1">
                Plasma reactor output
              </p>
            </div>
            <div className="flex items-center gap-1.5 mt-2">
              <TrendingUp className="w-3.5 h-3.5 text-amber-500" />
              <span className="text-[10px] text-amber-500 font-bold uppercase tracking-wider">
                {selectedSectorInfo.powerTrend === "elevated" ? "Elevated Load" : "Stable Load"}
              </span>
            </div>
          </div>

          {/* Card 4: Exotic Mass Yield */}
          <div className="bg-zinc-950 border border-zinc-800 hover:border-cyan-500/50 rounded-xl p-5 transition-all flex flex-col justify-between h-[140px] shadow-lg group">
            <div className="flex justify-between items-start text-xs text-slate-400 font-semibold tracking-wide">
              <span>EXOTIC MASS YIELD</span>
              <Database className="w-4 h-4 text-cyan-400" />
            </div>
            <div>
              <div className="font-mono text-2xl font-bold text-white tracking-tight">
                {selectedSectorInfo.massYield}
              </div>
              <p className="text-[11px] text-slate-400 mt-1">
                Dark matter synthesis rate
              </p>
            </div>
            <div className="flex items-center gap-1.5 mt-2">
              <div className="flex gap-1 h-3 items-end">
                <span className="w-[3px] h-[8px] bg-cyan-500/60 rounded-sm"></span>
                <span className="w-[3px] h-[6px] bg-cyan-500/40 rounded-sm"></span>
                <span className="w-[3px] h-[10px] bg-cyan-500/80 rounded-sm"></span>
                <span className="w-[3px] h-[12px] bg-cyan-500 rounded-sm animate-pulse"></span>
              </div>
              <span className="text-[10px] text-cyan-400 font-bold uppercase tracking-wider">
                Synthesizing
              </span>
            </div>
          </div>
        </section>

        {/* ==========================================
            3. TEST RIG PERFORMANCE (2 COLUMNS)
           ========================================== */}
        <section className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          
          {/* Left Rig: Optimal (Alpha-9) */}
          <div className="sentio-highlight-card top border border-zinc-800 shadow-md">
            <div className="sentio-highlight-header">
              <div className="sentio-highlight-title text-emerald-400">
                <ShieldCheck className="w-5 h-5" />
                <span>Rig Alpha-9 (Graviton Emitter)</span>
              </div>
              <span className="sentio-badge sentio-badge-success">Optimal</span>
            </div>
            <div>
              <p className="sentio-highlight-dept text-white">99.2% Resonance Stability</p>
              <p className="sentio-highlight-desc">Continuous operation holding steady over 85 hours</p>
            </div>
            <div className="sentio-grid-3">
              <div className="sentio-grid-item">
                <span className="sentio-grid-label">Efficiency</span>
                <span className="sentio-grid-val text-white">94%</span>
              </div>
              <div className="sentio-grid-item">
                <span className="sentio-grid-label">Heat Dissipation</span>
                <span className="sentio-grid-val text-emerald-400 font-bold">Excellent</span>
              </div>
              <div className="sentio-grid-item">
                <span className="sentio-grid-label">Variance</span>
                <span className="sentio-grid-val text-white">0.01%</span>
              </div>
            </div>
            <div className="sentio-card-callout border-l-2 border-emerald-500">
              Peak performance holding steady. Quantum locking is fully engaged.
            </div>
          </div>

          {/* Right Rig: Critical (Delta-4) */}
          <div className="sentio-highlight-card attention border border-zinc-800 shadow-md">
            <div className="sentio-highlight-header">
              <div className="sentio-highlight-title text-rose-500">
                <ShieldAlert className="w-5 h-5 animate-pulse" />
                <span>Rig Delta-4 (Mass Alleviator)</span>
              </div>
              <span className="sentio-badge sentio-badge-danger">Critical</span>
            </div>
            <div>
              <p className="sentio-highlight-dept text-white">37% Field Degradation</p>
              <p className="sentio-highlight-desc">Severe core anomalies reported over 71 minutes</p>
            </div>
            <div className="sentio-grid-3">
              <div className="sentio-grid-item">
                <span className="sentio-grid-label">Efficiency</span>
                <span className="sentio-grid-val text-white">42%</span>
              </div>
              <div className="sentio-grid-item">
                <span className="sentio-grid-label">Heat Dissipation</span>
                <span className="sentio-grid-val text-rose-500 font-bold">Critical</span>
              </div>
              <div className="sentio-grid-item">
                <span className="sentio-grid-label">Variance</span>
                <span className="sentio-grid-val text-white">8.4%</span>
              </div>
            </div>
            <div className="sentio-card-callout border-l-2 border-rose-500 bg-rose-950/20 text-rose-300">
              <strong>Primary issue:</strong> Micro-fractures in the containment coil. Recommend immediate shutdown.
            </div>
          </div>
        </section>

        {/* ==========================================
            4. TELEMETRY CHARTS SECTION (2 COLUMNS)
           ========================================== */}
        <section className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          
          {/* Chart 1: Energy Distribution */}
          <div className="sentio-card">
            <div className="mb-4">
              <h5 className="font-bold text-white text-base">Energy Distribution</h5>
              <p className="text-xs text-slate-400">Power allocation ratio across containment and generators</p>
            </div>
            <div className="flex flex-col sm:flex-row items-center justify-between gap-6">
              <div className="w-[180px] h-[180px]">
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie
                      data={energyDistributionData}
                      cx="50%"
                      cy="50%"
                      innerRadius={55}
                      outerRadius={75}
                      paddingAngle={4}
                      dataKey="value"
                    >
                      {energyDistributionData.map((entry, index) => (
                        <Cell key={`cell-${index}`} fill={entry.color} />
                      ))}
                    </Pie>
                  </PieChart>
                </ResponsiveContainer>
              </div>
              
              {/* Legends */}
              <div className="flex flex-col gap-3 flex-1 w-full">
                {energyDistributionData.map((item, idx) => (
                  <div key={idx} className="flex items-center justify-between border-b border-zinc-800/50 pb-2 text-xs">
                    <div className="flex items-center gap-2">
                      <span className="w-2.5 h-2.5 rounded-sm" style={{ backgroundColor: item.color }}></span>
                      <span className="text-slate-300 font-medium">{item.name}</span>
                    </div>
                    <span className="font-mono font-bold text-white">{item.value}%</span>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Chart 2: Field Stability Over Time */}
          <div className="sentio-card">
            <div className="mb-4">
              <h5 className="font-bold text-white text-base">Field Stability Over Time</h5>
              <p className="text-xs text-slate-400">Gravitational wave stability deviations and baselines</p>
            </div>
            <div className="h-[185px] w-full">
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={fieldStabilityData} margin={{ top: 5, right: 10, left: -20, bottom: 0 }}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#1e293b" opacity={0.3} />
                  <XAxis dataKey="time" stroke="#64748b" fontSize={10} tickLine={false} />
                  <YAxis stroke="#64748b" fontSize={10} tickLine={false} domain={[-2, 2]} />
                  <Tooltip 
                    contentStyle={{ backgroundColor: "#090d16", borderColor: "#1e293b", borderRadius: "8px" }}
                    labelStyle={{ color: "#94a3b8", fontSize: "11px", fontWeight: "bold" }}
                  />
                  <Line 
                    type="monotone" 
                    dataKey="baseline" 
                    stroke="#475569" 
                    strokeDasharray="4 4" 
                    dot={false}
                    name="Target Baseline (0G)"
                  />
                  <Line 
                    type="monotone" 
                    dataKey="gForce" 
                    stroke="#06b6d4" 
                    strokeWidth={2}
                    activeDot={{ r: 6 }}
                    dot={{ stroke: "#06b6d4", strokeWidth: 2, r: 2 }}
                    name="Measured G-force"
                  />
                </LineChart>
              </ResponsiveContainer>
            </div>
          </div>
        </section>

        {/* ==========================================
            5. SUB-SYSTEM ANALYSIS (TABLE)
           ========================================== */}
        <section className="sentio-card">
          <div className="mb-4">
            <h5 className="font-bold text-white text-base">Sub-system Analysis</h5>
            <p className="text-xs text-slate-400">Live operational log and heat tolerance matrix for active graviton grids</p>
          </div>
          <div className="overflow-x-auto">
            <table className="min-w-full text-left border-collapse">
              <thead>
                <tr className="border-b border-zinc-800 bg-zinc-900/40">
                  <th 
                    onClick={() => handleSort("component")} 
                    className="p-3 text-xs font-bold text-slate-400 cursor-pointer hover:text-white transition-all select-none"
                  >
                    <div className="flex items-center gap-1">
                      Component <ArrowUpDown className="w-3 h-3" />
                    </div>
                  </th>
                  <th 
                    onClick={() => handleSort("uptime")} 
                    className="p-3 text-xs font-bold text-slate-400 cursor-pointer hover:text-white transition-all select-none"
                  >
                    <div className="flex items-center gap-1">
                      Uptime (h) <ArrowUpDown className="w-3 h-3" />
                    </div>
                  </th>
                  <th 
                    onClick={() => handleSort("temp")} 
                    className="p-3 text-xs font-bold text-slate-400 cursor-pointer hover:text-white transition-all select-none"
                  >
                    <div className="flex items-center gap-1">
                      Temperature (K) <ArrowUpDown className="w-3 h-3" />
                    </div>
                  </th>
                  <th 
                    onClick={() => handleSort("output")} 
                    className="p-3 text-xs font-bold text-slate-400 cursor-pointer hover:text-white transition-all select-none"
                  >
                    <div className="flex items-center gap-1">
                      Field Output (N) <ArrowUpDown className="w-3 h-3" />
                    </div>
                  </th>
                  <th 
                    onClick={() => handleSort("status")} 
                    className="p-3 text-xs font-bold text-slate-400 cursor-pointer hover:text-white transition-all select-none"
                  >
                    <div className="flex items-center gap-1">
                      Status <ArrowUpDown className="w-3 h-3" />
                    </div>
                  </th>
                </tr>
              </thead>
              <tbody>
                {tableData.map((row, idx) => {
                  let badgeClass = "bg-zinc-800 text-slate-400";
                  if (row.status === "Optimal") badgeClass = "bg-emerald-500/10 text-emerald-400 border border-emerald-500/25";
                  else if (row.status === "Stable") badgeClass = "bg-purple-500/10 text-purple-400 border border-purple-500/25";
                  else if (row.status === "Warning") badgeClass = "bg-amber-500/10 text-amber-400 border border-amber-500/25";
                  else if (row.status === "Critical") badgeClass = "bg-rose-500/10 text-rose-400 border border-rose-500/25";
                  
                  return (
                    <tr key={idx} className="border-b border-zinc-800/50 hover:bg-zinc-900/10 transition-all">
                      <td className="p-3 text-xs font-bold text-white">{row.component}</td>
                      <td className="p-3 text-xs font-mono text-slate-300">{row.uptime}h</td>
                      <td className="p-3 text-xs font-mono text-slate-300">{row.temp}K</td>
                      <td className="p-3 text-xs font-mono text-slate-300">{row.output.toLocaleString()}N</td>
                      <td className="p-3 text-xs">
                        <span className={`sentio-badge ${badgeClass} text-[10px] font-bold`}>
                          {row.status}
                        </span>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </section>

        {/* ==========================================
            6. LIVE DIAGNOSTICS EXPLORER (SPLIT VIEW UI)
           ========================================== */}
        <section className="sentio-card">
          <div className="border-b border-zinc-800 pb-4 mb-4">
            <h5 className="font-bold text-white text-base">Live Diagnostics Explorer</h5>
            <p className="text-xs text-slate-400">Search and select an individual anomaly log to analyze primary vectors.</p>
          </div>
          
          <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
            
            {/* Left Panel (1/3 List) */}
            <div className="md:col-span-1 flex flex-col gap-3">
              <div className="explorer-search-row">
                <div className="explorer-input-wrapper">
                  <span className="explorer-search-icon">🔍</span>
                  <input 
                    type="text" 
                    placeholder="Search logs, events, or sectors..." 
                    className="outline-none"
                    disabled 
                  />
                </div>
                
                {/* Sentiment-styled severity pills */}
                <div className="explorer-pills">
                  <button className="explorer-pill-btn active">All</button>
                  <button className="explorer-pill-btn">Critical</button>
                  <button className="explorer-pill-btn">Warning</button>
                </div>
              </div>
              
              <div className="explorer-list divide-y divide-zinc-800/30">
                {anomalyLogs.map((log) => {
                  let sevClass = "bg-zinc-800 text-slate-400";
                  if (log.severity === "Critical") sevClass = "sentio-badge-danger bg-rose-500/10 text-rose-400";
                  else if (log.severity === "High") sevClass = "bg-amber-500/10 text-amber-400";
                  else if (log.severity === "Medium") sevClass = "bg-purple-500/10 text-purple-400";
                  
                  return (
                    <button
                      key={log.id}
                      onClick={() => setSelectedLogId(log.id)}
                      className={`explorer-item-btn transition-all text-left ${
                        selectedLogId === log.id ? "bg-zinc-900/60 border-l-2 border-cyan-500" : ""
                      }`}
                    >
                      <div className="flex justify-between items-center gap-2 mb-1.5">
                        <span className="font-bold text-xs text-white">{log.system}</span>
                        <span className={`sentio-badge text-[9px] uppercase ${sevClass}`}>
                          {log.severity}
                        </span>
                      </div>
                      <p className="text-xs text-slate-400 line-clamp-1 truncate mb-1">
                        {log.output}
                      </p>
                      <div className="text-[10px] text-slate-500 font-mono">
                        {log.id} · {log.loggedAt}
                      </div>
                    </button>
                  );
                })}
              </div>
            </div>

            {/* Right Panel (2/3 Details) */}
            <div className="md:col-span-2 bg-zinc-950 border border-zinc-800 rounded-xl p-6 flex flex-col justify-between min-h-[380px]">
              
              {/* Card Header */}
              <div className="flex justify-between items-start gap-4">
                <div>
                  <span className="font-mono text-xs text-cyan-400 font-bold uppercase tracking-wider">
                    {selectedLog.id}
                  </span>
                  <h4 className="text-lg font-bold text-white mt-1">
                    {selectedLog.system}
                  </h4>
                  <p className="text-xs text-slate-400 mt-0.5">
                    Location: {selectedLog.sector} · Dynamic Field Array
                  </p>
                </div>
                <span className={`sentio-badge ${
                  selectedLog.severity === "Critical" 
                    ? "sentio-badge-danger bg-rose-500/10 text-rose-400" 
                    : "bg-amber-500/10 text-amber-400"
                } text-xs font-bold uppercase`}>
                  {selectedLog.severity}
                </span>
              </div>
              
              {/* Metadata rows */}
              <div className="grid grid-cols-3 gap-4 border-y border-zinc-800/80 py-4 my-4">
                <div className="flex flex-col">
                  <span className="text-[10px] text-slate-500 uppercase font-bold tracking-wide">
                    Impact Factor
                  </span>
                  <span className="font-mono text-sm font-bold text-white mt-1">
                    {selectedLog.impactScore} / 10
                  </span>
                </div>
                <div className="flex flex-col">
                  <span className="text-[10px] text-slate-500 uppercase font-bold tracking-wide">
                    Log Status
                  </span>
                  <span className="text-xs text-emerald-400 font-bold mt-1.5 uppercase tracking-wider flex items-center gap-1">
                    <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"></span> Active
                  </span>
                </div>
                <div className="flex flex-col">
                  <span className="text-[10px] text-slate-500 uppercase font-bold tracking-wide">
                    Timestamp
                  </span>
                  <span className="text-xs text-slate-300 font-semibold mt-1.5">
                    {selectedLog.loggedAt}
                  </span>
                </div>
              </div>

              {/* Quote diagnostics message */}
              <div className="flex flex-col gap-2">
                <span className="text-[10px] text-slate-500 uppercase font-bold tracking-wide">
                  Diagnostic Output
                </span>
                <blockquote className="border-l-2 border-cyan-500 pl-4 py-1.5 font-mono text-xs leading-relaxed text-slate-200 bg-zinc-900/30 rounded-r-md">
                  {selectedLog.output}
                </blockquote>
              </div>

              {/* Recommendation Callout */}
              <div className="mt-6 bg-zinc-900/60 border border-zinc-800 rounded-lg p-4">
                <span className="text-[10px] text-slate-500 uppercase font-bold tracking-wide block mb-1">
                  AI Protocol Recommendation
                </span>
                <p className="text-xs text-slate-300 leading-relaxed">
                  {selectedLog.recommendation}
                </p>
              </div>
            </div>

          </div>
        </section>

        {/* ==========================================
            7. EXTREMES SECTION (2 COLUMNS)
           ========================================== */}
        <section className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          
          {/* Column 1: Peak Tolerances */}
          <div>
            <div className="mb-4">
              <h5 className="font-bold text-emerald-400 text-base flex items-center gap-2">
                <ShieldCheck className="w-5 h-5" /> Peak Tolerances
              </h5>
              <p className="text-xs text-slate-400">Highest lift capacities achieved during containment stability</p>
            </div>
            
            <div className="flex flex-col gap-3">
              {peakTolerances.map((run, idx) => (
                <div key={idx} className="bg-zinc-950 border border-zinc-800 hover:border-emerald-500/20 rounded-xl p-4 transition-all flex flex-col sm:flex-row justify-between sm:items-center gap-4">
                  <div>
                    <span className="font-mono text-xs text-slate-500 font-bold">{run.id}</span>
                    <h6 className="text-sm font-bold text-white mt-0.5">{run.engineer}</h6>
                  </div>
                  <div className="flex gap-4 text-xs font-medium">
                    <div className="flex flex-col sm:text-right">
                      <span className="text-[10px] text-slate-500 uppercase tracking-wide">Max Lift</span>
                      <span className="text-white font-mono mt-0.5">{run.metricValue}</span>
                    </div>
                    <div className="flex flex-col sm:text-right">
                      <span className="text-[10px] text-slate-500 uppercase tracking-wide">Stress Delta</span>
                      <span className="text-emerald-400 font-mono mt-0.5">{run.stressFactor}</span>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Column 2: Catastrophic Failures */}
          <div>
            <div className="mb-4">
              <h5 className="font-bold text-rose-500 text-base flex items-center gap-2">
                <ShieldAlert className="w-5 h-5 animate-pulse" /> Catastrophic Failures
              </h5>
              <p className="text-xs text-slate-400">Severe quantum fluctuations causing field collapses</p>
            </div>
            
            <div className="flex flex-col gap-3">
              {catastrophicFailures.map((run, idx) => (
                <div key={idx} className="bg-zinc-950 border border-zinc-800 hover:border-rose-500/20 rounded-xl p-4 transition-all flex flex-col sm:flex-row justify-between sm:items-center gap-4">
                  <div>
                    <span className="font-mono text-xs text-slate-500 font-bold">{run.id}</span>
                    <h6 className="text-sm font-bold text-white mt-0.5">{run.engineer}</h6>
                  </div>
                  <div className="flex gap-4 text-xs font-medium">
                    <div className="flex flex-col sm:text-right">
                      <span className="text-[10px] text-slate-500 uppercase tracking-wide">Collapse Vector</span>
                      <span className="text-white font-semibold mt-0.5">{run.metricValue}</span>
                    </div>
                    <div className="flex flex-col sm:text-right">
                      <span className="text-[10px] text-slate-500 uppercase tracking-wide">Decay Rate</span>
                      <span className="text-rose-500 font-mono mt-0.5">{run.stressFactor}</span>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </section>

        {/* ==========================================
            8. AI PREDICTIVE ENGINE
           ========================================== */}
        <section className="bg-zinc-950 border border-zinc-800 p-6 rounded-xl shadow-lg relative overflow-hidden">
          {/* Animated Background glow grid */}
          <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_top_right,rgba(168,85,247,0.06),transparent_60%)] pointer-events-none"></div>
          
          <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-6 relative z-10">
            <div>
              <h5 className="font-bold text-white text-base flex items-center gap-2">
                <Cpu className="w-5 h-5 text-purple-400 animate-spin-slow" />
                AI Predictive Maintenance
              </h5>
              <p className="text-xs text-slate-400 mt-1 max-w-xl leading-relaxed">
                Quantum neural-net analysis of all active antigrav systems. Runs localized event simulations to predict imminent component anomalies.
              </p>
            </div>
            
            <div className="flex items-center gap-4">
              <button 
                onClick={triggerSimulation} 
                disabled={isSimulating}
                className="flex items-center justify-center gap-2 px-5 py-2.5 rounded-lg bg-purple-600 hover:bg-purple-700 disabled:bg-purple-950 text-white font-bold text-xs uppercase tracking-wider transition-all select-none shadow-[0_0_12px_rgba(168,85,247,0.3)] disabled:shadow-none min-w-[150px]"
              >
                {isSimulating ? (
                  <span className="flex items-center gap-1.5">
                    <span className="w-3.5 h-3.5 border-2 border-white/30 border-t-white rounded-full animate-spin"></span>
                    Simulating...
                  </span>
                ) : (
                  <>
                    <Play className="w-3.5 h-3.5 fill-current" />
                    Run Simulation
                  </>
                )}
              </button>
            </div>
          </div>

          {/* Simulation Progress bar and results overlay */}
          {isSimulating && (
            <div className="mt-5 w-full bg-zinc-900 border border-zinc-800/80 rounded-lg p-3 animate-fade-slide">
              <div className="flex justify-between items-center text-[10px] text-slate-500 font-mono mb-1.5 uppercase font-bold">
                <span>Executing localized failure projections...</span>
                <span>{simulationProgress}%</span>
              </div>
              <div className="w-full bg-zinc-850 h-2 rounded-full overflow-hidden">
                <div 
                  className="bg-purple-500 h-full shadow-[0_0_8px_rgba(168,85,247,0.6)] transition-all duration-300"
                  style={{ width: `${simulationProgress}%` }}
                ></div>
              </div>
            </div>
          )}

          {predictionResult && (
            <div className="mt-5 bg-purple-950/20 border border-purple-500/30 rounded-lg p-4 animate-fade-slide flex flex-col sm:flex-row justify-between gap-4">
              <div>
                <span className="text-[10px] font-bold uppercase text-purple-400 tracking-wider">
                  Simulation Outcome
                </span>
                <h6 className="text-sm font-bold text-white mt-1">
                  Imminent Component Failure Predicted: <span className="text-purple-400 font-mono font-black">{predictionResult.component}</span>
                </h6>
                <p className="text-xs text-slate-400 mt-1">
                  Recommended Protocol: {predictionResult.recommendedAction}
                </p>
              </div>
              
              <div className="flex gap-4 text-xs font-semibold sm:text-right shrink-0">
                <div className="flex flex-col">
                  <span className="text-[10px] text-slate-500 uppercase tracking-wide">Probability</span>
                  <span className="text-rose-500 font-mono font-bold mt-1 text-sm">{predictionResult.probability}%</span>
                </div>
                <div className="flex flex-col">
                  <span className="text-[10px] text-slate-500 uppercase tracking-wide">Time to Failure</span>
                  <span className="text-white font-semibold mt-1">{predictionResult.timeToFailure}</span>
                </div>
              </div>
            </div>
          )}
        </section>

        {/* Footer info summary */}
        <footer className="border-t border-zinc-800 pt-4 text-center text-xs text-slate-500">
          A.R.C. Antigravity Propulsion Core · Test Site Sector 7 · Live telemetry encrypted at AES-256
        </footer>

      </div>
    </div>
  );
}
