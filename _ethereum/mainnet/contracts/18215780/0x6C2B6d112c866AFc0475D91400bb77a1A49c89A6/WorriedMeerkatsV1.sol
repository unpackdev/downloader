// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./ERC721SeaDropUpgradeable.sol";

/**
 * @title WorriedMeerkatsV1
 *
 *                                ....
 *                            ...........
 *                         ................
 *                    ..........................
 *                    ...........................
 *                    ..........................
 *                    ............................
 *                   .............................
 *                   ............................
 *                     ........................
 *                        ..................
 *                           ............
 *                           ............
 *                           ............
 *                          ...............
 *                        ..................
 *                       ....................
 *                      ......................
 *                   ...........................
 *                  .............................
 *                 ..............................
 *                 ...............................
 */
contract WorriedMeerkatsV1 is ERC721SeaDropUpgradeable {
    // V1 - staking
    event Staked(address wallet, uint256 tokenId, uint256 stakedAt);
    event Unstaked(address wallet, uint256 tokenId, uint256 unstakedAt);

    struct StakeInfo {
        bool staked;
        uint256 stakedAt;
    }
    mapping(uint256 => StakeInfo) private _staked;

    // Array with all staked token ids
    uint256[] private _allStaked;

    // Mapping from token id to position in the allStaked array
    mapping(uint256 => uint256) private _allStakedIndex;

    /**
     * @notice Initialize the token contract with its name, symbol and allowed SeaDrop addresses.
     */
    function initialize(
        string memory name,
        string memory symbol,
        address[] memory allowedSeaDrop
    ) external initializer initializerERC721A {
        ERC721SeaDropUpgradeable.__ERC721SeaDrop_init(
            name,
            symbol,
            allowedSeaDrop
        );
    }

    // like mintSeadDrop but for owner
    function safeMint(address to, uint256 quantity)
        public
        onlyOwner
        nonReentrant
    {
        if (_totalMinted() + quantity > maxSupply()) {
            revert MintQuantityExceedsMaxSupply(
                _totalMinted() + quantity,
                maxSupply()
            );
        }
        _safeMint(to, quantity);
    }

    struct MultiMintAmount {
        address to;
        uint256 amount;
    }

    function multiMint(MultiMintAmount[] memory mints) public onlyOwner {
        for (uint256 i = 0; i < mints.length; i++) {
            safeMint(mints[i].to, mints[i].amount);
        }
    }

    function stake(uint256 tokenId) public {
        require(
            ownerOf(tokenId) == msg.sender,
            "You are not the owner of the token"
        );

        require(!_staked[tokenId].staked, "Token already staked");

        _staked[tokenId] = StakeInfo({
            staked: true,
            stakedAt: block.timestamp
        });

        _allStakedIndex[tokenId] = _allStaked.length;
        _allStaked.push(tokenId);

        emit Staked(msg.sender, tokenId, block.timestamp);
    }

    function stakeInfo(uint256 tokenId) public view returns (StakeInfo memory) {
        return _staked[tokenId];
    }

    function unstake(uint256 tokenId) public {
        require(
            ownerOf(tokenId) == msg.sender,
            "You are not the owner of the token"
        );

        require(_staked[tokenId].staked, "Token not staked");

        _staked[tokenId].staked = false;

        // To prevent a gap in the tokens array,
        // we swap token to unstake with the last
        // token in _allStaked (swap and pop).
        uint256 lastTokenIndex = _allStaked.length - 1;
        uint256 tokenIndex = _allStakedIndex[tokenId];

        uint256 lastTokenId = _allStaked[lastTokenIndex];

        _allStaked[tokenIndex] = lastTokenId;
        _allStakedIndex[lastTokenId] = tokenIndex;

        delete _allStakedIndex[tokenId];
        _allStaked.pop();

        emit Unstaked(msg.sender, tokenId, block.timestamp);
    }

    function allStaked() public view returns (uint256[] memory) {
        return _allStaked;
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256
    ) internal virtual override {
        if (from != address(0) && to != address(0)) {
            require(!_staked[startTokenId].staked, "Token staked");
        }
    }
}
