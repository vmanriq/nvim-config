-- AWS CDK snippets for TypeScript / TSX
-- Loaded via luasnip.loaders.from_lua (configured in init.lua)
local ls = require 'luasnip'
local s = ls.snippet
local i = ls.insert_node
local t = ls.text_node
local fmt = require('luasnip.extras.fmt').fmt

local cdk_snippets = {
  -- CDK Stack boilerplate
  s(
    'cdkstack',
    fmt(
      [[
import * as cdk from 'aws-cdk-lib';
import {{ Construct }} from 'constructs';

export interface {1}StackProps extends cdk.StackProps {{
  {2}
}}

export class {1}Stack extends cdk.Stack {{
  constructor(scope: Construct, id: string, props: {1}StackProps) {{
    super(scope, id, props);

    {3}
  }}
}}
]],
      { i(1, 'My'), i(2, '// custom props'), i(0, '// resources') }
    )
  ),

  -- CDK Construct
  s(
    'cdkconstruct',
    fmt(
      [[
import {{ Construct }} from 'constructs';

export interface {1}Props {{
  {2}
}}

export class {1} extends Construct {{
  constructor(scope: Construct, id: string, props: {1}Props) {{
    super(scope, id);

    {3}
  }}
}}
]],
      { i(1, 'MyConstruct'), i(2, ''), i(0, '') }
    )
  ),

  -- Lambda Function
  s(
    'cdklambda',
    fmt(
      [[
const {1} = new lambda.Function(this, '{2}', {{
  runtime: lambda.Runtime.NODEJS_20_X,
  handler: '{3}.handler',
  code: lambda.Code.fromAsset('{4}'),
  timeout: cdk.Duration.seconds({5}),
  memorySize: {6},
  environment: {{
    {7}
  }},
}});
]],
      {
        i(1, 'fn'),
        i(2, 'MyFunction'),
        i(3, 'index'),
        i(4, 'lambda'),
        i(5, '30'),
        i(6, '512'),
        i(0, ''),
      }
    )
  ),

  -- NodejsFunction (preferred for TS lambdas)
  s(
    'cdknodejs',
    fmt(
      [[
const {1} = new NodejsFunction(this, '{2}', {{
  entry: path.join(__dirname, '{3}'),
  handler: 'handler',
  runtime: lambda.Runtime.NODEJS_20_X,
  timeout: cdk.Duration.seconds({4}),
  memorySize: {5},
  bundling: {{
    minify: true,
    sourceMap: true,
    target: 'node20',
    externalModules: ['@aws-sdk/*'],
  }},
  environment: {{
    {6}
  }},
}});
]],
      {
        i(1, 'fn'),
        i(2, 'MyFunction'),
        i(3, '../src/handler.ts'),
        i(4, '30'),
        i(5, '512'),
        i(0, ''),
      }
    )
  ),

  -- API Gateway REST
  s(
    'cdkapi',
    fmt(
      [[
const {1} = new apigateway.RestApi(this, '{2}', {{
  restApiName: '{3}',
  defaultCorsPreflightOptions: {{
    allowOrigins: apigateway.Cors.ALL_ORIGINS,
    allowMethods: apigateway.Cors.ALL_METHODS,
    allowHeaders: ['Content-Type', 'Authorization'],
  }},
  deployOptions: {{
    stageName: '{4}',
    tracingEnabled: true,
  }},
}});
]],
      { i(1, 'api'), i(2, 'MyApi'), i(3, 'my-api'), i(0, 'prod') }
    )
  ),

  -- DynamoDB Table
  s(
    'cdkdyn',
    fmt(
      [[
const {1} = new dynamodb.Table(this, '{2}', {{
  tableName: '{3}',
  partitionKey: {{ name: '{4}', type: dynamodb.AttributeType.{5} }},
  {6}
  billingMode: dynamodb.BillingMode.PAY_PER_REQUEST,
  removalPolicy: cdk.RemovalPolicy.{7},
}});
]],
      {
        i(1, 'table'),
        i(2, 'MyTable'),
        i(3, 'my-table'),
        i(4, 'pk'),
        i(5, 'STRING'),
        i(6, "sortKey: { name: 'sk', type: dynamodb.AttributeType.STRING },"),
        i(0, 'RETAIN'),
      }
    )
  ),

  -- SQS Queue
  s(
    'cdksqs',
    fmt(
      [[
const {1} = new sqs.Queue(this, '{2}', {{
  queueName: '{3}',
  visibilityTimeout: cdk.Duration.seconds({4}),
  retentionPeriod: cdk.Duration.days({5}),
  deadLetterQueue: {{
    queue: {6},
    maxReceiveCount: {7},
  }},
}});
]],
      {
        i(1, 'queue'),
        i(2, 'MyQueue'),
        i(3, 'my-queue'),
        i(4, '30'),
        i(5, '14'),
        i(6, 'dlq'),
        i(0, '3'),
      }
    )
  ),

  -- S3 Bucket
  s(
    'cdks3',
    fmt(
      [[
const {1} = new s3.Bucket(this, '{2}', {{
  bucketName: '{3}',
  encryption: s3.BucketEncryption.S3_MANAGED,
  blockPublicAccess: s3.BlockPublicAccess.BLOCK_ALL,
  enforceSSL: true,
  versioned: {4},
  removalPolicy: cdk.RemovalPolicy.{5},
}});
]],
      { i(1, 'bucket'), i(2, 'MyBucket'), i(3, 'my-bucket'), i(4, 'true'), i(0, 'RETAIN') }
    )
  ),
}

ls.add_snippets('typescript', cdk_snippets)
ls.add_snippets('typescriptreact', cdk_snippets)

return {}
