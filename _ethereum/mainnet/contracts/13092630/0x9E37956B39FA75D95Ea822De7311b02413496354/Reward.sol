// contracts/Reward.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./IERC721Enumerable.sol";

contract Reward is Ownable {
    using SafeMath for uint256;
    using SafeMath for uint32;

    struct ERC721Config {
        // total supply of the ERC721 contract
        uint32 totalSupply;
        // total supply of the ERC721 contract multiplied by 100
        uint32 totalSupply_100;
        // the integer ratio donated to the token hodlers in the range of [0, 100]
        uint16 ratio;
        // flag to enable and disable the claim
        bool enableClaim;
    }

    // mapping from token ID to accumulated ETH balance
    uint256[] private _tClaimed;
    uint256 private _tBalance;
    // accumulated ETH balance reserved to the contract owner
    uint256 private _oBalance;
    // the associated IERC721 contract
    IERC721Enumerable private _nft;
    // configuration data structure
    ERC721Config private _config;

    /**
     * @dev receive fallback function where reward is distributed
     */
    receive() external payable {
        uint256 tValue = (((msg.value).mul(_config.ratio))).div(_config.totalSupply_100); // x = (value * ratio) / N * 100
        uint256 oValue =   (msg.value).sub((_config.totalSupply.mul(tValue)));            // y = (value) - (N * x)

        _tBalance = _tBalance.add(tValue);
        _oBalance = _oBalance.add(oValue);
    }

    /**
     * @dev Constructor
     * The parameters are:
     * nftAddress - address of the ERC721 contract
     * totalSupply - total supply of the ERC721 contract
     * startIndex - the token starting index (i.e., generally or 0 or 1)
     * ratio - the integer ratio donated to the token hodlers in the range of [0, 100]
     */
    constructor (
        address nftAddress,
        uint32  totalSupply,
        uint32  startIndex,
        uint16  ratio
    ) {
        require(nftAddress != address(0), "nftAddress not valid");
        require(ratio <= 100, "ratio not valid");
        require(startIndex == 0, "this contract supports only startIndex equal 0");

        _nft = IERC721Enumerable(nftAddress);

        _tBalance = 0;
        _oBalance = 0;

        _tClaimed = new uint256[](totalSupply);

        for (uint i = 0; i < totalSupply; i++) {
            _tClaimed[i] = 0;
        }

        _config.totalSupply     = totalSupply;
        _config.totalSupply_100 = uint32(totalSupply.mul(100));
        _config.ratio           = ratio;
        _config.enableClaim     = true;
    }

    /**
     * @dev Claim the accumulated balance for the tokenId.
     * Returns true in case of success, false in case of failure
     */
    function claimToken(uint256 tokenId) public returns (bool) {
        require(_config.enableClaim,  "claim disabled");
        require(_msgSender() == _nft.ownerOf(tokenId), "caller is not the token owner");

        uint256 amount  = _tBalance.sub(_tClaimed[tokenId]);
        bool    success = true;

        if (amount > 0) {
            _tClaimed[tokenId]  = _tClaimed[tokenId].add(amount);
            (success, )         = _msgSender().call{value:amount}("");
        }

        if (!success) {
            // no need to call throw here, just reset the amount owing
            // the sum is required since payout are coming async
            _tClaimed[tokenId]  = _tClaimed[tokenId].sub(amount);
        }

        return success;
    }

    /**
    * @dev Claim the accumulated balance for a list of tokenIds.
    * Returns true in case of success, false in case of failure
    */
    function claimTokens(uint256[] calldata tokenIds) public returns (bool) {
        require(_config.enableClaim, "claim disabled");
        require(tokenIds.length > 0, "array is empty");

        uint256[] memory amounts = new uint256[](tokenIds.length);

        uint256 totalAmount = 0;
        uint256 tmpAmount = 0;
        uint256 i;

        bool success = true;

        for (i = 0; i < tokenIds.length; i++) {
            require(_msgSender() == _nft.ownerOf(tokenIds[i]), "caller is not the token owner");
        }

        for (i = 0; i < tokenIds.length; i++) {
            tmpAmount               = _tBalance.sub(_tClaimed[tokenIds[i]]);
            amounts[i]              = tmpAmount;
            totalAmount             = totalAmount.add(tmpAmount);
            _tClaimed[tokenIds[i]]  = _tClaimed[tokenIds[i]].add(tmpAmount);
        }

        if (totalAmount > 0) {
            (success, ) = _msgSender().call{value:totalAmount}("");
        }

        if (!success) {
            // no need to call throw here, just reset all the amount owing
            // the sum is required since payout are coming async
            for (i = 0; i < tokenIds.length; i++) {
                _tClaimed[tokenIds[i]] = _tClaimed[tokenIds[i]].sub(amounts[i]);
            }
        }

        return success;
    }

    /**
     * @dev Claim the owner balance.
     * Returns true in case of success, false in case of failure
     */
    function claimOwner() public onlyOwner() returns (bool) {
        require(_config.enableClaim, "claim disabled");

        uint256 amount  = _oBalance;
        bool    success = true;

        if (amount > 0) {
            _oBalance   = _oBalance.sub(amount);
            (success, ) = _msgSender().call{value:amount}("");
        }

        if (!success) {
            // no need to call throw here, just reset all the amount owing
            // the sum is required since payout are coming async
            _oBalance = _oBalance.add(amount);
        }

        return success;
    }

    /**
    * @dev Returns the caller accumulated balance on its NFT tokens
    */
    function balanceOf(address wallet) public view returns (uint256) {
        uint256 totalAmount = 0;
        uint256 numTokens   = _nft.balanceOf(wallet);

        for (uint256 i = 0; i < numTokens; i++) {
            totalAmount = totalAmount.add( _tBalance.sub(_tClaimed[_nft.tokenOfOwnerByIndex(wallet, i)]) );
        }

        return totalAmount;
    }

    /**
     * @dev Returns the accumulated balance for the tokenId
     */
    function balanceOfToken(uint256 tokenId) public view returns (uint256) {
        require(tokenId < _config.totalSupply, "tokenID not valid");

        return _tBalance.sub(_tClaimed[tokenId]);
    }

    /**
    * @dev Returns the owner balance
    */
    function ownerBalance() public onlyOwner() view returns (uint256) {
        return _oBalance;
    }

    /**
    * @dev Enable or disable the claim[*]() functions
    */
    function setEnableClaim(bool flag) public onlyOwner() {
        _config.enableClaim = flag;
    }

    /**
    * @dev Set a new ratio value in the range of [0, 100]
    */
    function setRatio(uint16 ratio) public onlyOwner() {
        require(ratio <= 100, "ratio not valid");
        _config.ratio = ratio;
    }

    function getRatio() public view returns (uint16) {
        return _config.ratio;
    }

    /**
    * @dev Withdraw to 'destination' and destruct this contract (Callable by owner)
    */
    function destroy(address destination) onlyOwner() public {
        selfdestruct(payable(destination));
    }
    
}
