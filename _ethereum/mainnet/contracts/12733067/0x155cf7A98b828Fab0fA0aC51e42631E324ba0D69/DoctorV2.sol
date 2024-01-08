pragma solidity ^0.7.0;
pragma experimental ABIEncoderV2;


import "./Randomness.sol";


interface IMahin {
    function totalSupply() external view returns (uint256);
    function tokenByIndex(uint256 index) external view returns (uint256);
    function diagnose(uint256 tokenId) external;
}


// Replaces the builtin random generator with a fixed version.
contract DoctorV2 is Randomness, Ownable {
    IMahin public nft;

    constructor(VRFConfig memory vrfConfig, IMahin _nft)
            // 0.0000000008468506% - This has been pre-calculated to amount to 12.5%
            // start time is the deploy of the main ERC contract.
            Randomness(vrfConfig, 8468506, 1616625854
    ) {
        nft = _nft;
    }

    function _totalSupply() public view override returns (uint256) {
        return nft.totalSupply();
    }

    function _tokenByIndex(uint256 index) public view override returns (uint256) {
        return nft.tokenByIndex(index);
    }

    function _isDisabled() public view override returns (bool) {
        return false;
    }

    function onDiagnosed(uint256 tokenId) internal override {
        nft.diagnose(tokenId);
    }

    function setPerSecondProbability(uint _probabilityPerSecond) public onlyOwner {
        probabilityPerSecond = _probabilityPerSecond;
    }

    function setLastRollTime(uint timestamp) public onlyOwner {
        lastRollTime = timestamp;
    }
}
