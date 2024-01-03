contract AttendanceRules {
    mapping(uint256 => bool) private _visits;

    function visitThisBlock() internal view returns (bool) {
        return _visits[block.number];
    }

    function checkIn() internal {
        _visits[block.number] = true;
    }

    modifier oneBlockOneVisit() {

        require(
            !visitThisBlock(),
            'AttendanceRules: one block, one visit'
        );
        _;

        _visits[block.number] = true;
    }
}