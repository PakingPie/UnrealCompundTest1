float accumDensity = 0;
float transmittance = 1;
float3 lightEnergy = 0;
Density *= StepSize;
LightVector *= ShadowStepSize;
ShadowDensity *= ShadowStepSize;
float shadowThreshold = -log(ShadowThreshold)/ShadowDensity;

LocalCamVec = normalize(mul(Parameters.CameraVector, (float3x3)LWCToFloat(GetPrimitiveData(Parameters).WorldToLocal))) * StepSize;
for(int i = 0; i < MaxSteps; i++)
{
    float currSample = PseudoVolumeTexture(Tex, TexSampler, saturate(CurrPos), XYFrames, NumFrames).r;
    if(currSample > 0.001)
    {
        float3 lightPos = CurrPos;
        float shadowDist = 0;
        for(int s = 0; s < ShadowSteps; s++)
        {
            lightPos += LightVector;
            float lightSample = PseudoVolumeTexture(Tex, TexSampler, saturate(lightPos), XYFrames, NumFrames).r;

            float3 shadowBoxTest = floor(0.5 + abs(0.5 - lightPos));
            float exitShadowBox = shadowBoxTest.x + shadowBoxTest.y + shadowBoxTest.z;
            if(shadowDist > shadowThreshold || exitShadowBox >= 1) break;
            
            shadowDist += lightSample;
        }
    
        currSample = 1 - exp(-currSample * Density);
        lightEnergy += exp(-shadowDist * ShadowDensity) * currSample * transmittance;
        transmittance *= 1.0 - currSample;
    }

    CurrPos += -LocalCamVec;
}

// CurrPos -= LocalCamVec * StepSize;
// CurrPos += LocalCamVec * StepSize * FinalStepSize;
// float currSample = PseudoVolumeTexture(Tex, TexSampler, saturate(CurrPos), XYFrames, NumFrames).r;
// accumdens += currSample * FinalStepSize;
return float4(lightEnergy, transmittance);
