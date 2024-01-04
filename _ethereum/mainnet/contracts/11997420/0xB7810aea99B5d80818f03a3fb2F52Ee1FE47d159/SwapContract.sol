pragma solidity 0.6.4;

import "./AddXyz.sol";
import "./Ownable.sol";


contract SwapContract is OwnableUpgradeSafe {
    address public tokenAddress;

    constructor(address _tokenAddress)
        public
    {
        __Ownable_init_unchained();
        tokenAddress = _tokenAddress;
    }

    function allocateTokens(
        address[] memory _contributors,
        uint256[] memory _tokens
    ) public onlyOwner {
        require(_contributors.length == _tokens.length, "SwapContract: Invalid request length");
        for (uint256 i = 0; i < _contributors.length; i++) {
            _allocateTokens(
                _contributors[i],
                _tokens[i]
            );
        }
    }

    function _allocateTokens(
        address _contributor,
        uint256 _tokens
    ) private {
        AddXyz(tokenAddress).transfer(_contributor, _tokens);
    }
}

