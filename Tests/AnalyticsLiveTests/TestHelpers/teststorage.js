
storage.setValue("testString", "someString")
storage.setValue("testNumber", 120)
storage.setValue("testBool", true)
storage.setValue("testDict", { testString: "someString", testNumber: 120, testDict: { someValue: 1 } })
storage.setValue("testDate", new Date("2024-05-01T12:00:00Z"))
storage.setValue("testArray", [1, "test", { blah: 1 }])
storage.setValue("testNull", [1, null, "test"])

let testString = storage.getValue("testString")
let testNumber = storage.getValue("testNumber")
let testBool = storage.getValue("testBool")
let testDict = storage.getValue("testDict")
let testDate = storage.getValue("testDate")
let testArray = storage.getValue("testArray")
let testNull = storage.getValue("testNull")

storage.removeValue("testString")
storage.removeValue("testNumber")
storage.removeValue("testBool")
storage.removeValue("testDict")
storage.removeValue("testDate")
storage.removeValue("testArray")
storage.removeValue("testNull")

let remove1 = storage.getValue("testString") == undefined
let remove2 = storage.getValue("testNumber") == undefined
let remove3 = storage.getValue("tsetBool") == undefined
let remove4 = storage.getValue("testDict") == undefined
let remove5 = storage.getValue("testDate") == undefined
let remove6 = storage.getValue("testArray") == undefined
let remove7 = storage.getValue("testNull") == undefined

analytics.track("test", {
    testString: testString,
    testNumber: testNumber,
    testBool: testBool,
    testDict: testDict,
    testDate: testDate,
    testNull: testNull,
    testArray: testArray,
    remove: [
        remove1,
        remove2,
        remove3,
        remove4,
        remove5,
        remove6,
        remove7
    ]
})
