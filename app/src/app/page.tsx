'use client';

import { useEffect, useState } from 'react';
import { AppLayout } from '@/components/AppLayout';
import { KPICard } from '@/components/KPICard';
import { Chart } from '@/components/Chart';
import { DataTable } from '@/components/DataTable';
import { AskAI } from '@/components/AskAI';
import { ActionMemo } from '@/components/ActionMemo';
import { GeoMap } from '@/components/GeoMap';
import { ArchitectureDiagram } from '@/components/ArchitectureDiagram';

interface DemoNarrative {
  title: string;
  duration: string;
  thesis: string;
  tabs: any[];
}

export default function HomePage() {
  const [narrative, setNarrative] = useState<DemoNarrative | null>(null);
  const [data, setData] = useState<any>(null);

  useEffect(() => {
    fetch('/demo_narrative.json')
      .then((r) => r.json())
      .then(setNarrative)
      .catch(() => {});
    fetch('/api/data')
      .then((r) => r.json())
      .then(setData)
      .catch(() => {});
  }, []);

  const title = narrative?.title || 'SEA AWS Demo';

  const executiveCockpit = (
    <div className="space-y-6">
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <KPICard title="Cold Chain Compliance" value="94.2%" status="warning" />
        <KPICard title="Product Loss (QTD)" value="฿180M" status="danger" />
        <KPICard title="Predicted Failures (7d)" value="12" status="warning" />
        <KPICard title="Active Shipments" value="835" status="neutral" />
      </div>
      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <div className="lg:col-span-1">
          <GeoMap
            country="thailand"
            markers={[{"label": "Bangkok", "value": "Hub: 847 trucks", "color": "green", "size": "lg"}, {"label": "Chiang Mai", "value": "Depot: -18.1\u00b0C avg", "color": "green", "size": "md"}, {"label": "Laem Chabang", "value": "Port: 124 containers", "color": "green", "size": "md"}, {"label": "Surat Thani", "value": "Truck-247: ALERT", "color": "red", "size": "md"}, {"label": "Khon Kaen", "value": "Depot: -17.8\u00b0C", "color": "amber", "size": "sm"}, {"label": "Rayong", "value": "Cold store: OK", "color": "green", "size": "sm"}]}
            routes={[{"from": "Bangkok", "to": "Chiang Mai", "color": "#EF4444"}, {"from": "Bangkok", "to": "Laem Chabang", "color": "#10B981"}, {"from": "Bangkok", "to": "Surat Thani", "color": "#F59E0B"}]}
            title="Geographic Overview"
            height={400}
          />
        </div>
        <div className="lg:col-span-1 grid grid-cols-1 gap-4">
      <div className="grid grid-cols-1 gap-4 grid-cols-1">
        <Chart
          data={data?.timeseries || [{ period: 'Jan', value: 112 }, { period: 'Feb', value: 118 }, { period: 'Mar', value: 135 }, { period: 'Apr', value: 148 }, { period: 'May', value: 156 }, { period: 'Jun', value: 142 }, { period: 'Jul', value: 138 }, { period: 'Aug', value: 151 }, { period: 'Sep', value: 144 }, { period: 'Oct', value: 132 }, { period: 'Nov', value: 121 }, { period: 'Dec', value: 115 }]}
          type="line"
          xKey="period"
          yKeys={[{ key: 'value', name: 'Excursions' }]}
          title="Temperature Excursions (Weekly)"
        />
        <Chart
          data={data?.categories || [{ category: 'North', count: 82 }, { category: 'Central', count: 74 }, { category: 'South', count: 91 }, { category: 'Highland', count: 68 }, { category: 'Coastal', count: 77 }]}
          type="bar"
          xKey="category"
          yKeys={[{ key: 'count', name: 'Count' }]}
          title="Excursions by Route Corridor"
        />
      </div>
        </div>
      </div>
      <DataTable
        columns={[
          { key: 'id', header: 'Truck ID' },
          { key: 'name', header: 'Route' },
          { key: 'status', header: 'Temp Status' },
          { key: 'value', header: 'Current °C' },
        ]}
        data={data?.entities || []}
        title="Fleet Temperature Status"
      />
    </div>
  );

  const domainTab1 = (
    <div className="space-y-6">
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <KPICard title="Avg Transit Temp" value="-18.3°C" />
        <KPICard title="Door-Open Events Today" value="47" />
        <KPICard title="On-Time Delivery" value="91.8%" />
      </div>
      <Chart
        data={data?.detail || [{ x: 'Mon', y: 24 }, { x: 'Tue', y: 28 }, { x: 'Wed', y: 22 }, { x: 'Thu', y: 31 }, { x: 'Fri', y: 26 }, { x: 'Sat', y: 19 }, { x: 'Sun', y: 23 }]}
        type="area"
        xKey="x"
        yKeys={[{ key: 'y', name: 'Avg Temp °C' }]}
        title="Temperature Distribution by Depot"
        height={400}
      />
    </div>
  );

  const domainTab2 = (
    <div className="space-y-6">
      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <Chart
          data={data?.breakdown || [{ label: 'Zone North', value: 35 }, { label: 'Zone Central', value: 28 }, { label: 'Zone South', value: 22 }, { label: 'Zone East', value: 15 }]}
          type="pie"
          xKey="label"
          yKeys={[{ key: 'value', name: 'Risk Score' }]}
          title="Failure Risk by Equipment Age"
        />
        <ActionMemo
          persona={{ name: 'Jintana Srikumpa', role: 'Cold Chain Ops Manager' }}
          context={{}}
          onGenerate={async () => {
            const memos = [
              {
                subject: 'Urgent: Operational Action Required',
                body: `Dear Leadership Team,\n\nBased on our analysis of the latest operational data, I am writing to recommend immediate action on the following critical items.\n\nKey Findings:\n- Performance metrics indicate a deviation from target KPIs in several areas\n- Predictive models suggest these trends will continue without intervention\n- Estimated impact: 12-15% improvement in efficiency if addressed within 2 weeks\n\nI recommend we schedule a review meeting this week to align on next steps.\n\nBest regards`,
                urgency: 'HIGH' as const,
                actions: ['Dispatch technician to Truck-247 (compressor degrading)', 'Re-route Bangkok→Chiang Mai via backup fleet', 'Schedule maintenance for 12 flagged units'],
              },
              {
                subject: 'Weekly Performance Summary & Recommendations',
                body: `Dear Team,\n\nPlease find below the AI-generated weekly performance summary.\n\nHighlights:\n- Overall performance trending 8% above quarterly targets\n- Three areas identified for optimization with potential 20% cost savings\n- New anomaly patterns detected that warrant monitoring\n\nRecommended next steps are outlined below. Please review and confirm priority assignments by end of week.\n\nRegards`,
                urgency: 'MEDIUM' as const,
                actions: ['Dispatch technician to Truck-247 (compressor degrading)', 'Re-route Bangkok→Chiang Mai via backup fleet', 'Schedule maintenance for 12 flagged units'],
              },
              {
                subject: 'Strategic Initiative: Data-Driven Optimization',
                body: `Dear Stakeholders,\n\nOur AI analysis has identified a significant opportunity for operational optimization.\n\nExecutive Summary:\n- Current utilization rate: 78% (target: 90%)\n- Root cause analysis points to 3 primary factors\n- Projected ROI of recommended changes: 2.4x within 6 months\n\nThe attached data supports a phased implementation approach starting with the highest-impact items.\n\nPlease advise on scheduling a planning session.\n\nBest regards`,
                urgency: 'HIGH' as const,
                actions: ['Dispatch technician to Truck-247 (compressor degrading)', 'Re-route Bangkok→Chiang Mai via backup fleet', 'Schedule maintenance for 12 flagged units'],
              },
            ];
            return memos[Math.floor(Math.random() * memos.length)];
          }}
        />
      </div>
    </div>
  );

  const askAiTab = (
    <div className="h-[600px]">
      <AskAI
        title="Ask AI"
        sampleQuestions={[
          'Which trucks exceeded -15°C in the last 24 hours?',
          'Show predicted compressor failures for next 7 days',
          'What is the spoilage cost trend for Bangkok→Laem Chabang?',
        ]}
        mode="sql"
        onSubmit={async (question, mode) => {
          return {
            answer: `[Demo Mode] Response to: "${question}" (${mode} mode). Connect to Snowflake for live data.`,
            sql: mode === 'sql' ? 'SELECT * FROM CURATED.SUMMARY LIMIT 10;' : undefined,
          };
        }}
      />
    </div>
  );

  const architectureTab = (
    <ArchitectureDiagram
      snowflakeFeatures={['Dynamic Tables (5-min refresh)', 'ML Functions (Forecast + Anomaly)', 'Cortex Search + Agent', 'Semantic View + Intelligence', 'Alerts + Notifications']}
      awsServices={[{ name: 'Amazon S3', role: 'Strategy Docs' }, { name: 'Amazon S3 + Kinesis', role: 'Integration' }, { name: 'Amazon SNS', role: 'Integration' }, { name: 'Amazon QuickSight + Q', role: 'Integration' }]}
    />
  );

  const tabs = [
    { id: 'executive-cockpit', label: 'Executive Cockpit', icon: '📊', content: executiveCockpit },
    { id: 'domain-1', label: 'Fleet Monitoring', icon: '📈', content: domainTab1 },
    { id: 'domain-2', label: 'Predictive Alerts', icon: '⚡', content: domainTab2 },
    { id: 'ask-ai', label: 'Ask AI', icon: '🤖', content: askAiTab },
    { id: 'architecture', label: 'Architecture & Data', icon: '🏗️', content: architectureTab },
  ];

  return (
    <AppLayout
      title={title}
      tabs={tabs}
      narrative={narrative}
    />
  );
}
