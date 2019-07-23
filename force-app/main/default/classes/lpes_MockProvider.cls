public class lpes_MockProvider implements System.StubProvider 
{
    private static map<string,object> methodToReturnValue = new map<string,object>();
    private static lpes_MockProvider mockProvider;

    private lpes_MockProvider(){}

    public static lpes_MockProvider getInstance()
    {
        if (mockProvider==null)
            mockProvider = new lpes_MockProvider();

        return mockProvider;
    }

    public static Object createMock(Type typeToMock, map<string,object> returnValueMap)
    {
        methodToReturnValue = returnValueMap;
        return Test.createStub(typeToMock, lpes_MockProvider.getInstance());
    }

    public Object handleMethodCall(Object stubbedObject, String stubbedMethodName,
                                Type returnType, List<Type> listOfParamTypes,
                                List<String> listOfParamNames, List<Object> listOfArgs)

    {
        return methodToReturnValue.get(stubbedMethodName);
    }
}