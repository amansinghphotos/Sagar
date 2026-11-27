import Testing

@testable import Look

@Test func theWindowSizesGrowFromNarrowToWide() {
    let sizes = WindowSize.allCases
    #expect(sizes == [.narrow, .standard, .wide])
    for (smaller, larger) in zip(sizes, sizes.dropFirst()) {
        #expect(smaller.width < larger.width && smaller.height < larger.height)
    }
}

@Test func theNarrowestWindowIsSearchsSmallest() {
    #expect(WindowSize.narrow.width == 640 && WindowSize.narrow.height == 420)
}
