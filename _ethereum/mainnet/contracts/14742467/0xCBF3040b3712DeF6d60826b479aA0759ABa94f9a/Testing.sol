contract Testing {

    function encode(address gauge) public returns(bytes32) {
      return keccak256(abi.encodePacked(gauge));
    }
}