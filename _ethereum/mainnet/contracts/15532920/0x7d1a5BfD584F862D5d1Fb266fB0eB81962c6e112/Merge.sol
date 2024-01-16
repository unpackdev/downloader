contract Merge {
  function hasMergeHappened() external view returns (bool) {
    return block.difficulty == 0 || block.difficulty > type(uint64).max;
  }
}