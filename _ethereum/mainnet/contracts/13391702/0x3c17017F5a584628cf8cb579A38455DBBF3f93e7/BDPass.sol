// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./draft-EIP712.sol";
import "./Ownable.sol";

contract BDPass is ERC721, EIP712, Ownable {
    // EIP712 Feature
    bytes32 public constant TYPEHASH =
        keccak256("PassReq(address receiver,uint256 amount)");
    struct PassReq {
        address receiver;
        uint256 amount;
    }

    bool public paused = true;
    string public baseURI;

    uint256 public totalSupply = 0;
    uint256 public constant MAX_SUPPLY = 1250;

    uint256 public claimUntil;

    event Paused();
    event Unpaused();
    event ClaimPass(address claimer, uint256 amount);
    event SetClaimUntil(uint256 claimUntil);
    event RetrieveUnclaimedPass(address to, uint256 passAmount);

    constructor(
        string memory __name,
        string memory __symbol,
        string memory __baseURI
    ) ERC721(__name, __symbol) EIP712(__name, "1") {
        baseURI = __baseURI;
    }

    function setClaimUntil(uint256 _claimUntil) external onlyOwner {
        claimUntil = _claimUntil;
        emit SetClaimUntil(_claimUntil);
    }

    function pause() external onlyOwner {
        paused = true;
        emit Paused();
    }

    function unpause() external onlyOwner {
        paused = false;
        emit Unpaused();
    }

    function tokenURI(uint256)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return baseURI;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        require(!_exists(tokenId) || !paused, "token transfer while paused");
    }

    function claimPass(
        uint256 _passAmount,
        uint8 vSig,
        bytes32 rSig,
        bytes32 sSig
    ) external {
        require(block.timestamp < claimUntil, "Claim period has been ended");
        require(balanceOf(msg.sender) == 0, "Already received pass");

        require(totalSupply + _passAmount <= MAX_SUPPLY, "Exceeds max supply");

        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(TYPEHASH, msg.sender, _passAmount))
        );

        address signer = ecrecover(digest, vSig, rSig, sSig);
        require(signer == owner(), "Signature is not from the owner");

        for (uint256 i = totalSupply; i < _passAmount + totalSupply; i += 1) {
            _mint(msg.sender, i);
        }
        totalSupply += _passAmount;

        emit ClaimPass(msg.sender, _passAmount);
    }

    function retrieveUnclaimedPass(address _to, uint256 _passAmount)
        external
        onlyOwner
    {
        require(totalSupply + _passAmount <= MAX_SUPPLY, "Exceeds max supply");

        for (uint256 i = totalSupply; i < _passAmount + totalSupply; i += 1) {
            _mint(_to, i);
        }
        totalSupply += _passAmount;

        emit RetrieveUnclaimedPass(_to, _passAmount);
    }
}