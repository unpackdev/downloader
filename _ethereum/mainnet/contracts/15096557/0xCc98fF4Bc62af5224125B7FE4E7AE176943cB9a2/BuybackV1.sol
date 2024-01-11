// SPDX-License-Identifier: MIT

/**
 /$$$$$$$$ /$$   /$$  /$$$$$$ 
| $$_____/| $$  / $$ /$$__  $$
| $$      |  $$/ $$/| $$  \ $$
| $$$$$    \  $$$$/ | $$  | $$
| $$__/     >$$  $$ | $$  | $$
| $$       /$$/\  $$| $$  | $$
| $$$$$$$$| $$  \ $$|  $$$$$$/
|________/|__/  |__/ \______/ 
                              
*/

pragma solidity ^0.8.4;

import "./OwnableUpgradeable.sol";
import "./UUPSUpgradeable.sol";
import "./ReentrancyGuardUpgradeable.sol";
import "./AddressUpgradeable.sol";
import "./StringsUpgradeable.sol";

error BuybackContractNotApproved();
error WrongNumberOfReturnedPlanets();

interface Monolith {
    function claimMonolithBuyback(address to) external;
}

interface Exo {
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

contract BuybackV1 is Initializable, OwnableUpgradeable, UUPSUpgradeable, ReentrancyGuardUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    address public ownerWallet;
    uint256 public ratio;

    mapping(address => uint256) public balances;

    Monolith public monolith;
    Exo public exo;

    function initialize(address ownerWallet_, address monolithAddress, address exoAddress) external initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
        __ReentrancyGuard_init();

        ownerWallet = ownerWallet_;
        monolith = Monolith(monolithAddress);
        exo = Exo(exoAddress);
        ratio = 5;
    }

    /* solhint-disable-next-line no-empty-blocks */
    function _authorizeUpgrade(address _newImplementation) internal override onlyOwner {}

    function setMonolithAddress(address monolithAddress) public onlyOwner {
        monolith = Monolith(monolithAddress);
    }

    function getBalance(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    function setRatio(uint256 _ratio) public onlyOwner {
        ratio = _ratio;
    }

    function returnPlanet(uint256[] memory tokenIds) public {
        if (tokenIds.length != ratio) {
            revert WrongNumberOfReturnedPlanets();
        }
        bool isApproved = exo.isApprovedForAll(msg.sender, address(this));

        if (!isApproved) {
            revert BuybackContractNotApproved();
        }

        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            exo.transferFrom(msg.sender, ownerWallet, tokenId);
        }
        balances[msg.sender] += tokenIds.length;
        _claimMonolith();
    }

    function _claimMonolith() internal nonReentrant {
        balances[msg.sender] -= ratio;
        monolith.claimMonolithBuyback(msg.sender);
    }
}
