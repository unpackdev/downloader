// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Initializable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "./OwnableUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./ERC20CappedUpgradeable.sol";

contract SwampGold is Initializable, ContextUpgradeable,  OwnableUpgradeable, ERC20CappedUpgradeable {
    address public implementation;
    uint256 season;
    mapping(uint256 => mapping(uint256 => bool)) toadzSeasonClaimedByTokenId;
    mapping(uint256 => mapping(uint256 => bool)) flyzSeasonClaimedByTokenId;
    mapping(uint256 => mapping(uint256 => bool)) polzSeasonClaimedByTokenId;
    bool public paused;
    struct CyrptoContractInfo {
        address nftiContractAddress;
        IERC721EnumerableUpgradeable iContractAddress;
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

    function initialize() public initializer{
      __ERC20_init("Swamp Gold", "SGLD");
      __Ownable_init();
      ERC20CappedUpgradeable.__ERC20Capped_init_unchained(90000000 * (10**decimals()));
      init();
    }

    function init() internal {
        address toadziContractAddress = 0x1CB1A5e65610AEFF2551A50f76a87a7d3fB649C6;
        address flyziContractAddress = 0xf8b0a49dA21e6381f1cd3CF43445800abe852179;
        address polziContractAddress = 0x9aA03df95b6D3c6edFb53c09A4A8473d0D642D32;
        toadz.nftiContractAddress = toadziContractAddress;
        toadz.iContractAddress = IERC721EnumerableUpgradeable(toadziContractAddress);
        toadz.tokenAmount = 8500 * (10**decimals());
        toadz.tokenStartId = 1;
        toadz.tokenEndId = 7025;
        flyz.nftiContractAddress = flyziContractAddress;
        flyz.iContractAddress = IERC721EnumerableUpgradeable(flyziContractAddress);
        flyz.tokenAmount = 1500 * (10**decimals());
        flyz.tokenStartId = 1;
        flyz.tokenEndId = 7026;
        polz.nftiContractAddress = polziContractAddress;
        polz.iContractAddress = IERC721EnumerableUpgradeable(polziContractAddress);
        polz.tokenAmount = 1000 * (10**decimals());
        polz.tokenStartId = 1;
        polz.tokenEndId = 10000;
        season = 0;
        }

    function setPaused(bool _paused) public
        onlyOwner {
        paused = _paused;
    }

    function claimToadzById(uint256 tokenId) external {
        require(paused == false, "Contract Paused");
        require(
            _msgSender() == toadz.iContractAddress.ownerOf(tokenId),
            "MUST_OWN_TOKEN_ID"
        );

        _claimToadz(tokenId, _msgSender());
    }

    function claimFlyzById(uint256 tokenId) external {
        require(paused == false, "Contract Paused");
        require(
            _msgSender() == flyz.iContractAddress.ownerOf(tokenId),
            "MUST_OWN_TOKEN_ID"
        );

        _claimFlyz(tokenId, _msgSender());
    }

    function claimPolzById(uint256 tokenId) external {
        require(paused == false, "Contract Paused");
        require(
            _msgSender() == polz.iContractAddress.ownerOf(tokenId),
            "MUST_OWN_TOKEN_ID"
        );

        _claimPolz(tokenId, _msgSender());
    }
    function claimAllToadz() external {
        uint256 tokenBalanceOwner = toadz.iContractAddress.balanceOf(_msgSender());
        require(paused == false, "Contract Paused");
        require(tokenBalanceOwner > 0, "NO_TOKENS_OWNED");

        for (uint256 i = 0; i < tokenBalanceOwner; i++) {
            _claimToadz(
                toadz.iContractAddress.tokenOfOwnerByIndex(_msgSender(), i),
                _msgSender()
            );
        }
    }
    function claimAllFlyz() external {
        uint256 tokenBalanceOwner = flyz.iContractAddress.balanceOf(_msgSender());
        require(paused == false, "Contract Paused");
        require(tokenBalanceOwner > 0, "NO_TOKENS_OWNED");

        for (uint256 i = 0; i < tokenBalanceOwner; i++) {
            _claimFlyz(
                flyz.iContractAddress.tokenOfOwnerByIndex(_msgSender(), i),
                _msgSender()
            );
        }
    }
    function claimAllPolz() external {
        uint256 tokenBalanceOwner = polz.iContractAddress.balanceOf(_msgSender());
        require(paused == false, "Contract Paused");
        require(tokenBalanceOwner > 0, "NO_TOKENS_OWNED");

        for (uint256 i = 0; i < tokenBalanceOwner; i++) {
            _claimPolz(
                polz.iContractAddress.tokenOfOwnerByIndex(_msgSender(), i),
                _msgSender()
            );
        }
    }

    function _claimToadz(uint256 tokenId, address tokenOwner) internal {
        require(paused == false, "Contract Paused");
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
        require(paused == false, "Contract Paused");
        require(
            tokenId >= flyz.tokenStartId && tokenId <= flyz.tokenEndId,
            "TOKEN_ID_OUT_OF_RANGE"
        );

        require(
            !polzSeasonClaimedByTokenId[season][tokenId],
            "GOLD_CLAIMED_FOR_TOKEN_ID"
        );

        polzSeasonClaimedByTokenId[season][tokenId] = true;

        _mint(tokenOwner, flyz.tokenAmount);
        _claimedFlyz.push(tokenId);
    }


    function _claimPolz(uint256 tokenId, address tokenOwner) internal {
        require(paused == false, "Contract Paused");
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

    function SetToadzGold(uint256 toadzGold)
        public
        onlyOwner
    {
        toadz.tokenAmount = toadzGold * (10**decimals());
    }
    function SetFlyzGold(uint256 flyzGold)
        public
        onlyOwner
    {
        flyz.tokenAmount = flyzGold * (10**decimals());
    }
    function SetPolzGold(uint256 polzGold)
        public
        onlyOwner
    {
        polz.tokenAmount = polzGold * (10**decimals());
    }
    function upgradeTo(address _newImplementation) external onlyOwner
    {
        require(implementation != _newImplementation, "Not Owner");
        _setImplementation(_newImplementation);
    }
    function _setImplementation(address _newImp) internal {
        implementation = _newImp;
    }
    function DAOMint(uint256 amountDisplayValue) external onlyOwner {
        _mint(owner(), amountDisplayValue * (10**decimals()));
    }

}