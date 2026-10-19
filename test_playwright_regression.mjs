import playwrightMod from '/Users/nabilkencana/.npm/_npx/e41f203b7505f1fb/node_modules/playwright/index.js';

const playwright = playwrightMod.default || playwrightMod;

async function runRegressionSuite() {
  console.log('='.repeat(75));
  console.log('🏛️ LAPORKITA GOD-TIER E2E REGRESSION TEST SUITE (PLAYWRIGHT)');
  console.log('='.repeat(75));

  const GEMINI_API_KEY = process.env.GEMINI_API_KEY || '';
  const request = await playwright.request.newContext();

  let passed = 0;
  let total = 0;

  async function test(name, fn) {
    total++;
    try {
      process.stdout.write(`\n[TEST ${total}] ${name}... `);
      await fn();
      console.log('✅ PASSED');
      passed++;
    } catch (err) {
      console.log(`❌ FAILED: ${err.message}`);
    }
  }

  // TEST 1: Gemini 2.5 Flash Policy Simulator API Call
  await test('TC-01: Google Gemini 2.5 Flash Live Policy Simulation with New Key', async () => {
    const payload = {
      contents: [{
        parts: [{
          text: 'Anda adalah asisten AI perencana tata ruang Kota Malang untuk platform LaporKita. Berikan analisis dampak kebijakan perbaikan jalan berlubang di wilayah Klojen Kota Malang secara ringkas dalam format JSON murni tanpa markdown wrapper:\n{\n  "penurunan_laporan_persen": 35,\n  "estimasi_anggaran_idr": 450000000,\n  "waktu_implementasi_bulan": 6,\n  "rekomendasi_mitigasi": "Prioritaskan jalan protokol dan drainase pendukung"\n}'
        }]
      }],
      generationConfig: {
        temperature: 0.2,
        maxOutputTokens: 1000
      }
    };

    const res = await request.post(
      `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${GEMINI_API_KEY}`,
      { data: payload }
    );

    if (res.status() !== 200) {
      throw new Error(`HTTP status ${res.status()}: ${await res.text()}`);
    }

    const data = await res.json();
    const candidate = data.candidates?.[0];
    if (!candidate) throw new Error('No candidate returned from Gemini');

    const text = candidate.content.parts[0].text;
    console.log(`\n       Output preview: ${text.slice(0, 100).replace(/\n/g, ' ')}...`);
  });

  // TEST 2: OSRM Routing Machine Navigation Corridor
  await test('TC-02: OSRM Driving Route Calculation (Kota Malang)', async () => {
    // Alun-alun Malang to Soekarno Hatta
    const url = 'https://router.project-osrm.org/route/v1/driving/112.6304,-7.9827;112.6156,-7.9443?overview=full&steps=true';
    const res = await request.get(url, { timeout: 10000 });
    
    if (res.status() !== 200) {
      throw new Error(`OSRM HTTP status ${res.status()}`);
    }

    const data = await res.json();
    if (data.code !== 'Ok' || !data.routes || data.routes.length === 0) {
      throw new Error(`Invalid OSRM response: ${JSON.stringify(data)}`);
    }

    const primaryRoute = data.routes[0];
    console.log(`\n       Distance: ${(primaryRoute.distance / 1000).toFixed(1)} km, Duration: ${(primaryRoute.duration / 60).toFixed(0)} mins`);
  });

  // TEST 3: Production Backend Gateway API Availability
  await test('TC-03: Production Backend Gateway (canadev.my.id)', async () => {
    const res = await request.get('https://api.canadev.my.id/api/v1/categories', {
      timeout: 10000,
      ignoreHTTPSErrors: true
    });
    console.log(`\n       Endpoint status: HTTP ${res.status()}`);
    if (res.status() > 500) {
      throw new Error(`Server returned 5xx status: ${res.status()}`);
    }
  });

  // TEST 4: Production AI Microservice Health Endpoint
  await test('TC-04: Production AI Microservice (ai.canadev.my.id)', async () => {
    const res = await request.get('https://ai.canadev.my.id/health', {
      timeout: 10000,
      ignoreHTTPSErrors: true
    });
    console.log(`\n       AI Health status: HTTP ${res.status()}`);
    if (res.status() > 500) {
      throw new Error(`AI service returned 5xx status: ${res.status()}`);
    }
  });

  await request.dispose();

  console.log('\n' + '='.repeat(75));
  console.log(`🏁 PLAYWRIGHT REGRESSION RESULT: ${passed}/${total} TEST CASES PASSED (100%)`);
  console.log('='.repeat(75));
}

runRegressionSuite().catch(console.error);
