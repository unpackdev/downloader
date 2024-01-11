// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4;

import "./SafeERC20.sol";
import "./draft-ERC20Permit.sol";
import "./draft-IERC20Permit.sol";
import "./ReentrancyGuard.sol";
import "./IERC721.sol";

contract GenesisNftStake is ERC20Permit, ReentrancyGuard {
    using SafeERC20 for IERC20;

    address public immutable nftToken;
    address public immutable nftKeyGenesis;
    mapping(uint256 => address) public stakedKeys; // maps tokenId => address
    mapping(address => uint256) public stakedAddress; // maps address => number of keys staked

    event NewStakedKey(uint256 indexed tokenId, address indexed staker, uint256 totalStakedKeys);

    constructor(address _nftToken, address _nftKeyGenesis)
        ERC20Permit("Staked NFT.com Genesis Key")
        ERC20("Staked NFT.com Genesis Key", "sNFT")
    {
        nftToken = _nftToken;
        nftKeyGenesis = _nftKeyGenesis;
    }

    /**
     @notice internal helper function to call allowance for a token
     @param _owner user allowing permit
     @param spender contract allowed to spent balance
     @param v vSig
     @param r rSig
     @param s sSig
    */
    function permitXNFT(
        address _owner,
        address spender,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private {
        return IERC20Permit(nftToken).permit(_owner, spender, 2**256 - 1, 2**256 - 1, v, r, s);
    }

    /**
     @notice function for allowing a user to stake
     @param _amount amount of NFT tokens to stake
     @param _tokenId of Genesis Key being staked
     @param v optional vSig param for permit
     @param r optional rSig param for permit
     @param s optional sSig param for permit
    */
    function enter(
        uint256 _amount,
        uint256 _tokenId,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public nonReentrant {
        // no stake yet
        if (stakedKeys[_tokenId] != msg.sender) {
            // checks
            require(IERC721(nftKeyGenesis).ownerOf(_tokenId) == msg.sender, "!GK1");

            // effects: assigned key to msg.sender
            stakedKeys[_tokenId] = msg.sender;
            stakedAddress[msg.sender] += 1;

            // interactions
            IERC721(nftKeyGenesis).transferFrom(msg.sender, address(this), _tokenId);

            emit NewStakedKey(_tokenId, msg.sender, stakedAddress[msg.sender]);
        }

        // only apply approve permit for first time
        if (IERC20(address(this)).allowance(msg.sender, address(this)) < _amount) {
            permitXNFT(msg.sender, address(this), v, r, s); // approve xNFT token
        }

        IERC20(nftToken).safeTransferFrom(msg.sender, address(this), _amount);

        uint256 totalNftTokenLocked = IERC20(nftToken).balanceOf(address(this));
        uint256 totalSupply = totalSupply();

        if (totalSupply == 0 || totalNftTokenLocked == 0) {
            _mint(msg.sender, _amount);
        } else {
            uint256 xNftTokenAmount = (_amount * totalSupply) / totalNftTokenLocked;
            _mint(msg.sender, xNftTokenAmount);
        }
    }

    // simply collects NFT tokens without withdrawing Gen Key
    function collectTokens(uint256 _xNftAmount, uint256 _tokenId) public nonReentrant {
        require(stakedKeys[_tokenId] == msg.sender, "!GEN_KEY");
        uint256 totalSupply = totalSupply();

        uint256 nftAmount = (_xNftAmount * (IERC20(nftToken).balanceOf(address(this)))) / totalSupply;
        _burn(msg.sender, _xNftAmount);
        IERC20(nftToken).safeTransfer(msg.sender, nftAmount);
    }

    function leave(uint256 _xNftAmount, uint256 _tokenId) public nonReentrant {
        require(stakedKeys[_tokenId] == msg.sender, "!GEN_KEY");
        require(stakedAddress[msg.sender] != 0, "GEN_KEY != 0");

        // reset assignment
        stakedKeys[_tokenId] = address(0x0);
        stakedAddress[msg.sender] -= 1;

        uint256 totalSupply = totalSupply();
        uint256 nftAmount = (_xNftAmount * (IERC20(nftToken).balanceOf(address(this)))) / totalSupply;
        _burn(msg.sender, _xNftAmount);
        IERC20(nftToken).safeTransfer(msg.sender, nftAmount);
        IERC721(nftKeyGenesis).transferFrom(address(this), msg.sender, _tokenId);
    }
}
