//SPDX-License-Identifier: BSD 3-Clause
pragma solidity 0.6.12;

import "./Ownable.sol";
import "./IERC721TokenCreator.sol";
import "./IERC721Creator.sol";

/**
 * @dev Registry token creators and tokens that implement iERC721Creator
 * @notice Thanks SuperRare! There is no afflication between SuperRare and 1stDibs
 */
contract FirstDibsCreatorRegistry is Ownable, IERC721TokenCreator {
    /**
     * @dev contract address => token ID mapping to payable creator address
     */
    mapping(address => mapping(uint256 => address payable)) private tokenCreators;

    /**
     * @dev Mapping of addresses that implement IERC721Creator.
     */
    mapping(address => bool) public iERC721Creators;

    /**
     * @dev Initializes the contract setting the iERC721Creators with the provided addresses.
     * @param _iERC721CreatorContracts address[] to set as iERC721Creators.
     */
    constructor(address[] memory _iERC721CreatorContracts) public {
        require(
            _iERC721CreatorContracts.length < 1000,
            'constructor: Cannot mark more than 1000 addresses as IERC721Creator'
        );
        for (uint8 i = 0; i < _iERC721CreatorContracts.length; i++) {
            require(
                _iERC721CreatorContracts[i] != address(0),
                'constructor: Cannot set the null address as an IERC721Creator'
            );
            iERC721Creators[_iERC721CreatorContracts[i]] = true;
        }
    }

    /**
     * @dev Gets the creator of the _tokenId on _nftAddress
     * @param _nftAddress address of the ERC721 contract
     * @param _tokenId uint256 ID of the token
     * @return payble address of the creator
     */
    function tokenCreator(address _nftAddress, uint256 _tokenId)
        external
        view
        override
        returns (address payable)
    {
        if (tokenCreators[_nftAddress][_tokenId] != address(0)) {
            return tokenCreators[_nftAddress][_tokenId];
        }

        if (iERC721Creators[_nftAddress]) {
            return IERC721Creator(_nftAddress).tokenCreator(_tokenId);
        }

        return address(0);
    }

    /**
     * @dev Sets _creator of the _tokenId on _nftAddress
     * @param _nftAddress address of the token contract
     * @param _creator payble address of the creator
     * @param _tokenId uint256 ID of the token
     */
    function setTokenCreator(
        address _nftAddress,
        address payable _creator,
        uint256 _tokenId
    ) external onlyOwner {
        require(
            _nftAddress != address(0),
            'FirstDibsCreatorRegistry: token address cannot be null'
        );
        require(_creator != address(0), 'FirstDibsCreatorRegistry: creator address cannot be null');
        tokenCreators[_nftAddress][_tokenId] = _creator;
    }

    /**
     * @dev Set an address as an IERC721Creator
     * @param _nftAddress address of the IERC721Creator contract
     */
    function setIERC721Creator(address _nftAddress) external onlyOwner {
        require(
            _nftAddress != address(0),
            'FirstDibsCreatorRegistry: token address cannot be null'
        );
        iERC721Creators[_nftAddress] = true;
    }
}
