pragma solidity 0.6.1;

interface publicCalls {
  function level3ActivationsFromDevCount (  ) external view returns ( uint256 );
  function level3ActivationsFromLevel1Count (  ) external view returns ( uint256 );
  function level3ActivationsFromLevel2Count (  ) external view returns ( uint256 );
  function NormalImportedAmountCount (  ) external view returns ( uint256 );
  function mneBurned (  ) external view returns ( uint256 );
}

contract MinereumCirculatingSupply {
    publicCalls public pc;
    
    constructor() public
    {
        pc = publicCalls(0x90E340e2d11E6Eb1D99E34D122D6fE0fEF3213fd);
    }

    function totalSupply() public view returns (uint256)
    {
        uint256 totalGenesisLevel3 = pc.level3ActivationsFromLevel1Count() + pc.level3ActivationsFromLevel2Count() + pc.level3ActivationsFromDevCount();
        uint256 daysSinceLaunch = (now - 1586563200) / 86400;
        
        return pc.NormalImportedAmountCount() + (totalGenesisLevel3 * 32000 * 6000 * daysSinceLaunch) - pc.mneBurned();
    }
}