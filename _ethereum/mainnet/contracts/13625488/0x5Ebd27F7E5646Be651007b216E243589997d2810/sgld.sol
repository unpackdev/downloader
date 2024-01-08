// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC20Capped.sol";
import "./Ownable.sol";
import "./IERC721Enumerable.sol";

contract SwampGold is Ownable, ERC20Capped {

    bool public paused;
    mapping(uint256 => mapping(uint256 => bool)) toadzSeasonClaimedByTokenId;
    mapping(uint256 => mapping(uint256 => bool)) flyzSeasonClaimedByTokenId;
    mapping(uint256 => mapping(uint256 => bool)) polzSeasonClaimedByTokenId;

    uint256 season = 0;

    struct CyrptoContractInfo {
        address lootContractAddress;
        IERC721Enumerable lootContract;
        uint256 tokenAmount;
        uint256 tokenStartId;
        uint256 tokenEndId;
    }
    
    CyrptoContractInfo toadz;
    CyrptoContractInfo flyz;
    CyrptoContractInfo polz;
    uint256[] private _claimedToadz;
    uint256[] private _claimedFlyz;
    uint256[] private _claimedPolz;
    
    function init() internal{
        
        address toadzContractAddress = 0x1CB1A5e65610AEFF2551A50f76a87a7d3fB649C6;
        address flyzContractAddress = 0xf8b0a49dA21e6381f1cd3CF43445800abe852179;
        address polzContractAddress = 0x9aA03df95b6D3c6edFb53c09A4A8473d0D642D32;
        
        toadz.lootContractAddress = toadzContractAddress;
        toadz.lootContract = IERC721Enumerable(toadzContractAddress);
        toadz.tokenAmount =  8500 * (10**decimals());
        toadz.tokenStartId = 1;
        toadz.tokenEndId = 7025;
        
        flyz.lootContractAddress = flyzContractAddress;
        flyz.lootContract = IERC721Enumerable(flyzContractAddress);
        flyz.tokenAmount =  1500 * (10**decimals());
        flyz.tokenStartId = 1;
        flyz.tokenEndId = 7026;
        
        polz.lootContractAddress = polzContractAddress;
        polz.lootContract = IERC721Enumerable(polzContractAddress);
        polz.tokenAmount =  1000 * (10**decimals());
        polz.tokenStartId = 1;
        polz.tokenEndId = 10000;
        
    } 
    
    function setPaused(bool _paused) public onlyOwner {
        paused = _paused;
    }

    function claimToadzById(uint256 tokenId) external {
        require(paused == false, "Contract Paused");
        require(
            _msgSender() == toadz.lootContract.ownerOf(tokenId),
            "MUST_OWN_TOKEN_ID"
        );

        _claimToadz(tokenId, _msgSender());
    }

    function claimFlyzById(uint256 tokenId) external {
        require(paused == false, "Contract Paused");
        require(
            _msgSender() == flyz.lootContract.ownerOf(tokenId),
            "MUST_OWN_TOKEN_ID"
        );

        _claimFlyz(tokenId, _msgSender());
    }

    function claimPolzById(uint256 tokenId) external {
        require(paused == false, "Contract Paused");
        require(
            _msgSender() == polz.lootContract.ownerOf(tokenId),
            "MUST_OWN_TOKEN_ID"
        );

        _claimPolz(tokenId, _msgSender());
    }
 
    function claimAllToadz() external {
        require(paused == false, "Contract Paused");
        uint256 tokenBalanceOwner = toadz.lootContract.balanceOf(_msgSender());

        require(tokenBalanceOwner > 0, "NO_TOKENS_OWNED");

        for (uint256 i = 0; i < tokenBalanceOwner; i++) {
            _claimToadz(
                toadz.lootContract.tokenOfOwnerByIndex(_msgSender(), i),
                _msgSender()
            );
        }
    }
 
    function claimAllFlyz() external {
        require(paused == false, "Contract Paused");
        uint256 tokenBalanceOwner = flyz.lootContract.balanceOf(_msgSender());

        require(tokenBalanceOwner > 0, "NO_TOKENS_OWNED");

        for (uint256 i = 0; i < tokenBalanceOwner; i++) {
            _claimFlyz(
                flyz.lootContract.tokenOfOwnerByIndex(_msgSender(), i),
                _msgSender()
            );
        }
    }
 
    function claimAllPolz() external {
        require(paused == false, "Contract Paused");
        uint256 tokenBalanceOwner = polz.lootContract.balanceOf(_msgSender());

        require(tokenBalanceOwner > 0, "NO_TOKENS_OWNED");

        for (uint256 i = 0; i < tokenBalanceOwner; i++) {
            _claimPolz(
                polz.lootContract.tokenOfOwnerByIndex(_msgSender(), i),
                _msgSender()
            );
        }
    }

    function _claimToadz(uint256 tokenId, address tokenOwner) internal {

        require(
            tokenId >= toadz.tokenStartId && tokenId <= toadz.tokenEndId,
            "TOKEN_ID_OUT_OF_RANGE"
        );

        require(
            !toadzSeasonClaimedByTokenId[season][tokenId],
            "GOLD_CLAIMED_FOR_TOKEN_ID"
        );

        toadzSeasonClaimedByTokenId[season][tokenId] = true;

        _mint(tokenOwner, toadz.tokenAmount);
        _claimedToadz.push(tokenId);
    }

    function _claimFlyz(uint256 tokenId, address tokenOwner) internal {

        require(
            tokenId >= flyz.tokenStartId && tokenId <= flyz.tokenEndId,
            "TOKEN_ID_OUT_OF_RANGE"
        );

        require(
            !flyzSeasonClaimedByTokenId[season][tokenId],
            "GOLD_CLAIMED_FOR_TOKEN_ID"
        );

        flyzSeasonClaimedByTokenId[season][tokenId] = true;

        _mint(tokenOwner, flyz.tokenAmount);
        _claimedFlyz.push(tokenId);

    }
    
    function _claimPolz(uint256 tokenId, address tokenOwner) internal {

        require(
            tokenId >= polz.tokenStartId && tokenId <= polz.tokenEndId,
            "TOKEN_ID_OUT_OF_RANGE"
        );

        require(
            !polzSeasonClaimedByTokenId[season][tokenId],
            "GOLD_CLAIMED_FOR_TOKEN_ID"
        );

        polzSeasonClaimedByTokenId[season][tokenId] = true;

        _mint(tokenOwner, polz.tokenAmount);
        _claimedPolz.push(tokenId);
    }

    function claimedToadz() public view returns (uint256[] memory) {
        return _claimedToadz;
    }
    
    function claimedFlyz() public view returns (uint256[] memory) {
        return _claimedFlyz;
    }
    
    function claimedPolz() public view returns (uint256[] memory) {
        return _claimedPolz;
    }
    
    function DAOMint(uint256 amountDisplayValue) external onlyOwner {
        require(paused == false, "Contract Paused");
        _mint(owner(), amountDisplayValue * (10**decimals()));
    }
    
    constructor() public Ownable() ERC20("Swamp Gold", "SGLD") ERC20Capped(90000000 * (10**decimals())) {
      init();
    }
    
}
   
