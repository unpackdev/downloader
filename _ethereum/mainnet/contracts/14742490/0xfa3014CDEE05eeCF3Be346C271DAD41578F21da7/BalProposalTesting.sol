contract BalProposalTesting {

    function encodeProposalByGauge(address gauge) public view returns(bytes32) {
      return keccak256(abi.encodePacked(gauge));
    }
}