#!/usr/bin/env python3
# make_architecture_diagram.py  (Enhanced with label improvements, layering, <<create>> stereotypes)

from graphviz import Digraph

g = Digraph("uav_rescue_arch",
            filename="architecture.gv", format="png",
            graph_attr={
                "rankdir": "TB",
                "splines": "ortho",
                "fontname": "Helvetica",
                "fontsize": "11",
                "nodesep": "1.0",
                "ranksep": "1.4 equally",
                "margin":  "0.3"
            })

# ────────────────────────────────────────────────────────────
# Helper to create a left- or right-side xlabel
def call(src, dst, text, side="right", **extra):
    """
    side = "right"  (default) → label is near upper-right
    side = "left"            → label is near lower-left
    """
    angle = "45" if side == "right" else "-45"
    edge_attrs = {
        "xlabel": text,
        "labeldistance": "1.3",
        "labelangle": angle,
        **extra
    }
    g.edge(src, dst, **edge_attrs)

# ────────────────────────────────────────────────────────────
# CONTROL / SCRIPTS LAYER
with g.subgraph(name="cluster_control") as c:
    c.attr(label="Scripts (Control Layer)",
           style="filled", color="#BFBFBF", fillcolor="#FBFBFB", pad="0.5")
    def box(name, label):
        c.node(name, label,
               shape="box", style="filled",
               fillcolor="#F2F2F2", fontsize="10")

    box("runRescueMission",  "runRescueMission.m")
    box("compareApproaches", "compareApproaches.m")
    box("demoAllScenarios",  "demoAllScenarios.m")

    c.node("cfg", "cfg (config)",
           shape="hexagon", style="filled",
           fillcolor="#D9E8FF", fontsize="10")

# CORE CLASSES LAYER
with g.subgraph(name="cluster_core") as c:
    c.attr(label="Core Classes Layer",
           style="filled", color="#BFBFBF", fillcolor="#FBFBFB", pad="0.5")
    c.node("BaseUAV", "«abstract»\\nBaseUAV",
           shape="box", style="rounded,filled",
           fillcolor="white", fontsize="10")
    c.node("AerialDrone",   "AerialDrone",
           shape="box", style="filled",
           fillcolor="#E4F7E8", fontsize="10")
    c.node("GroundVehicle", "GroundVehicle",
           shape="box", style="filled",
           fillcolor="#E4F7E8", fontsize="10")
    c.node("Survivor", "Survivor",
           shape="box", style="filled",
           fillcolor="#E4F7E8", fontsize="10")

    c.edge("AerialDrone",   "BaseUAV", arrowhead="empty")
    c.edge("GroundVehicle", "BaseUAV", arrowhead="empty")

# ENVIRONMENT & DATA LAYER
with g.subgraph(name="cluster_env") as c:
    c.attr(label="Environment & Data Layer",
           style="filled", color="#BFBFBF", fillcolor="#FBFBFB", pad="0.5")
    c.node("EnvironmentGenerator", "createEnvironment.m",
           shape="box", style="filled",
           fillcolor="#F2F2F2", fontsize="10")
    c.node("EnvStruct",
           "env struct\\n- groundMap\\n- occupancyMap3D\\n- survivors[]",
           shape="folder", style="filled",
           fillcolor="#D9E8FF", fontsize="10")
    c.node("RandomSeed", "randomSeed",
           shape="cylinder", style="filled",
           fillcolor="#D9E8FF", fontsize="10")

# ────────────────────────────────────────────────────────────
# CROSS-LAYER EDGES
call("runRescueMission", "EnvironmentGenerator", "invoke buildEnv()", minlen="2")

# Connect EnvGenerator -> EnvStruct
g.edge("EnvironmentGenerator", "EnvStruct", minlen="2", xlabel="occupancy data")

# env-to-UAV data (dashed)
g.edge("EnvStruct", "AerialDrone",   style="dashed", xlabel="3D map", labeldistance="1.3", labelangle="45")
g.edge("EnvStruct", "GroundVehicle", style="dashed", xlabel="2D map", labeldistance="1.3", labelangle="-45")

# Two edges from runRescueMission → UAVs, indicating <<create>>
call("runRescueMission", "AerialDrone",
     "<<create>>", side="right", minlen="2")
call("runRescueMission", "GroundVehicle",
     "<<create>>", side="left", minlen="2")

# For movement / rescue
call("runRescueMission", "AerialDrone", "moveStep / planPath", side="left", color="#555555")
call("runRescueMission", "GroundVehicle", "moveStep / planPath", side="right", color="#555555")

# rescues (UAV => Survivor)
call("AerialDrone",   "Survivor", "rescue", side="right")
call("GroundVehicle", "Survivor", "rescue", side="left")

# batching scripts
call("compareApproaches", "runRescueMission", "batch run", side="left")
g.edge("demoAllScenarios", "runRescueMission", xlabel="varied params")

# config & seed
g.edge("cfg", "runRescueMission", style="dashed", xlabel="test settings")
g.edge("RandomSeed", "EnvironmentGenerator", style="dashed", xlabel="rng seed")

# ────────────────────────────────────────────────────────────
g.render("architecture", cleanup=True)
print("✓ Generated architecture.png with layered diagram and labeled edges.")