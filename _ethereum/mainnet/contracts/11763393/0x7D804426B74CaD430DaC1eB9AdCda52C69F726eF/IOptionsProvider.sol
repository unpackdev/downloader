// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;
import "./IHegicOptions.sol"; 
import "./IERC721.sol";
import "./IERC721Enumerable.sol";

interface IOptionsProvider is IERC721, IERC721Enumerable {
    event Tokenized(address indexed account, uint indexed optionId);
    event Detokenized(address indexed account, uint indexed tokenId, bool burned);
    event Exercised(address indexed account, uint indexed tokenId, uint profit);

    function optionsProvider() external view returns(IHegicOptions);
    
    function createOption(
        uint _period,
        uint _amount,
        uint _strike,
        IHegicOptions.OptionType _optionType,
        address _to
    ) 
        payable
        external
        returns (uint newTokenId);

    function exerciseOption(uint _tokenId) external returns (uint profit);

    function tokenizeOption(uint _optionId, address _to) external returns (uint newTokenId);

    function detokenizeOption(uint _tokenId, bool _burnToken) external;

    function burnToken(uint _tokenId) external;

    function getOptionCostETH(
        uint _period,
        uint _amount,
        uint _strike,
        IHegicOptions.OptionType _optionType
    ) 
        external
        view
        returns (uint ethCost);
    
    function getUnderlyingOptionId(uint _tokenId) external view returns (uint);

    function getUnderlyingOptionParams(uint _tokenId) 
        external
        view 
        returns (
        IHegicOptions.State state,
        address payable holder,
        uint256 strike,
        uint256 amount,
        uint256 lockedAmount,
        uint256 premium,
        uint256 expiration,
        IHegicOptions.OptionType optionType);
    
    function isValidToken(uint _tokenId) external view returns (bool);
}