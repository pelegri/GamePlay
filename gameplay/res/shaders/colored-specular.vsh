// Uniforms
uniform mat4 u_worldViewProjectionMatrix;           // Matrix to transform a position to clip space.
uniform mat4 u_inverseTransposeWorldViewMatrix;     // Matrix to transform a normal to view space.
uniform mat4 u_worldMatrix;                         // Matrix to tranform a position to world space.
uniform vec3 u_cameraPosition;                      // Position of the camera.

// Inputs
attribute vec4 a_position;                          // Vertex Position (x, y, z, w)
attribute vec3 a_normal;                            // Vertex Normal (x, y, z)
attribute vec2 a_texCoord;                          // Vertex Texture Coordinate (u, v)

// Outputs
varying vec3 v_normalVector;                        // NormalVector in view space.
varying vec3 v_cameraDirection;                     // Camera direction

#if defined(SKINNING)

attribute vec4 a_blendWeights;
attribute vec4 a_blendIndices;

// 32 4x3 matrices as an array of floats
uniform vec4 u_matrixPalette[SKINNING_JOINT_COUNT * 3];

// Common vectors.
vec4 _skinnedPosition;
vec3 _skinnedNormal;

void skinPosition(float blendWeight, int matrixIndex)
{
    vec4 tmp;

    tmp.x = dot(a_position, u_matrixPalette[matrixIndex]);
    tmp.y = dot(a_position, u_matrixPalette[matrixIndex + 1]);
    tmp.z = dot(a_position, u_matrixPalette[matrixIndex + 2]);
    tmp.w = a_position.w;

    _skinnedPosition += blendWeight * tmp;
}

vec4 getPosition()
{
    _skinnedPosition = vec4(0.0);

    // Transform position to view space using 
    // matrix palette with four matrices used to transform a vertex.

    float blendWeight = a_blendWeights[0];
    int matrixIndex = int (a_blendIndices[0]) * 3;
    skinPosition(blendWeight, matrixIndex);

    blendWeight = a_blendWeights[1];
    matrixIndex = int(a_blendIndices[1]) * 3;
    skinPosition(blendWeight, matrixIndex);

    blendWeight = a_blendWeights[2];
    matrixIndex = int(a_blendIndices[2]) * 3;
    skinPosition(blendWeight, matrixIndex);

    blendWeight = a_blendWeights[3];
    matrixIndex = int(a_blendIndices[3]) * 3;
    skinPosition(blendWeight, matrixIndex);

    return _skinnedPosition;    
}

void skinNormal(float blendWeight, int matrixIndex)
{
    vec3 tmp;

    tmp.x = dot(a_normal, u_matrixPalette[matrixIndex].xyz);
    tmp.y = dot(a_normal, u_matrixPalette[matrixIndex + 1].xyz);
    tmp.z = dot(a_normal, u_matrixPalette[matrixIndex + 2].xyz);

    _skinnedNormal += blendWeight * tmp;
}

vec3 getNormal()
{
    _skinnedNormal = vec3(0.0);

    // Transform normal to view space using 
    // matrix palette with four matrices used to transform a vertex.

    float blendWeight = a_blendWeights[0];
    int matrixIndex = int (a_blendIndices[0]) * 3;
    skinNormal(blendWeight, matrixIndex);

    blendWeight = a_blendWeights[1];
    matrixIndex = int(a_blendIndices[1]) * 3;
    skinNormal(blendWeight, matrixIndex);

    blendWeight = a_blendWeights[2];
    matrixIndex = int(a_blendIndices[2]) * 3;
    skinNormal(blendWeight, matrixIndex);

    blendWeight = a_blendWeights[3];
    matrixIndex = int(a_blendIndices[3]) * 3;
    skinNormal(blendWeight, matrixIndex);

    return _skinnedNormal;
}

#else

vec4 getPosition()
{
    return a_position;    
}

vec3 getNormal()
{
    return a_normal;
}

#endif


#if defined(POINT_LIGHT)

uniform mat4 u_worldViewMatrix;                     // Matrix to tranform a position to view space.
uniform vec3 u_pointLightPosition;                  // Position
uniform float u_pointLightRangeInverse;             // Inverse of light range. 
varying vec4 v_vertexToPointLightDirection;         // Light direction w.r.t current vertex.

void applyLight(vec4 position)
{
    // World space position.
    vec4 positionWorldViewSpace = u_worldViewMatrix * position;
    
    // Compute the light direction with light position and the vertex position.
    vec3 lightDirection = u_pointLightPosition - positionWorldViewSpace.xyz;
    
    vec4 vertexToPointLightDirection;
    vertexToPointLightDirection.xyz = lightDirection;
    
    // Attenuation
    vertexToPointLightDirection.w = 1.0 - dot(lightDirection * u_pointLightRangeInverse, lightDirection * u_pointLightRangeInverse);

    // Output light direction.
    v_vertexToPointLightDirection =  vertexToPointLightDirection;
}

#elif defined(SPOT_LIGHT)

uniform mat4 u_worldViewMatrix;                     // Matrix to tranform a position to view space.
uniform vec3 u_spotLightPosition;                   // Position
uniform float u_spotLightRangeInverse;              // Inverse of light range.
varying vec3 v_vertexToSpotLightDirection;          // Light direction w.r.t current vertex.
varying float v_spotLightAttenuation;               // Attenuation of spot light.

void applyLight(vec4 position)
{
    // World space position.
    vec4 positionWorldViewSpace = u_worldViewMatrix * position;

    // Compute the light direction with light position and the vertex position.
    vec3 lightDirection = u_spotLightPosition - positionWorldViewSpace.xyz;

    // Attenuation
    v_spotLightAttenuation = 1.0 - dot(lightDirection * u_spotLightRangeInverse, lightDirection * u_spotLightRangeInverse);

    // Compute the light direction with light position and the vertex position.
    v_vertexToSpotLightDirection = lightDirection;
}

#else

void applyLight(vec4 position)
{
}

#endif

void main()
{
    vec4 position = getPosition();
    vec3 normal = getNormal();

    // Transform position to clip space.
    gl_Position = u_worldViewProjectionMatrix * position;

    // Transform normal to view space.
    mat3 inverseTransposeWorldViewMatrix = mat3(u_inverseTransposeWorldViewMatrix[0].xyz,
                                                u_inverseTransposeWorldViewMatrix[1].xyz,
                                                u_inverseTransposeWorldViewMatrix[2].xyz);
    v_normalVector = inverseTransposeWorldViewMatrix * normal;

    // Compute the camera direction.
    vec4 positionWorldSpace = u_worldMatrix * position;
    v_cameraDirection = u_cameraPosition - positionWorldSpace.xyz;

    // Apply light.
    applyLight(position);
}
