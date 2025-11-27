class CBridgeInterface {
    public func calcPlus(a: Int, b: Int) -> Int {
        let result = addTwoNumbers(Int32(a), Int32(b));
        //print("Result of C function: \(result)") // Output: Result of C function: 30
        return Int(result);
    }
}
