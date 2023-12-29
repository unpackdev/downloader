//SPDX-License-Identifier: MIT
//Fringe Drifter Scenes From The Fringe Contract Created by Swifty.eth
//POLYGON VERSION
//legal: https://fringedrifters.com/terms

pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./ERC1155.sol";

interface IERC20 {
    function transfer(address _to, uint256 _amount) external returns (bool);

    function balanceOf(address _from) external returns (uint256);
}

//errors
error NotWithdrawAddress();
error FailedToWithdraw();
error NotMinting();
error NotEnoughTokens();
error PastBoundsOfBatchLimit();
error PastSupply();
error AlreadyMinted();
error AuthenticationFailed();
error DoesNotExist();

contract FringeSpaceships is ERC1155, Ownable {
    string public name = "Spaceships - Fringe Drifters";
    string public symbol = "SFD";

    address private withdrawAccount =
        0x8ff8657929a02c0E15aCE37aAC76f47d1F5fbfC6;

    address private _FDPBContract = 0x8ff8657929a02c0E15aCE37aAC76f47d1F5fbfC6;

    function changeFDPBContractAddress(address newAddress) external onlyOwner {
        _FDPBContract = newAddress;
    }

    string internal _baseURI;

    mapping(uint256 => uint256) public SpaceshipValues;

    function changeSpaceshipValues(
        uint256 spaceshipId,
        uint256 spaceshipValue
    ) public onlyOwner {
        SpaceshipValues[spaceshipId] = spaceshipValue;
    }

    //modifiers.
    modifier withdrawAddressCheck() {
        if (msg.sender != withdrawAccount) revert NotWithdrawAddress();
        _;
    }

    constructor(string memory baseURI) ERC1155("") {
        _baseURI = baseURI;
    }

    //gifts spaceships in bulk, with specified spaceship.
    function gift(
        uint256 cardId,
        address[] calldata receivers,
        uint256[] calldata amounts
    ) external onlyOwner {
        for (uint256 i = 0; i < receivers.length; i++) {
            _mint(receivers[i], cardId, amounts[i], "");
        } //bulk mints.
    }

    function totalBalance() external view returns (uint256) {
        //gets total balance in account.
        return payable(address(this)).balance;
    }

    function burn(address sender, uint256 id, uint256 amount) external {
        _burn(sender, id, amount);
    }

    function buySpaceship(uint256 id, uint256 amount) external {
        uint256 spaceshipValue = SpaceshipValues[id];

        if (spaceshipValue == 0) revert DoesNotExist();

        FDPBContractTrait FDPBContract = FDPBContractTrait(_FDPBContract);

        uint256 balance = FDPBContract.balanceOf(
            msg.sender,
            FDPBContract.PBId()
        );

        if (balance < (spaceshipValue * amount)) revert NotEnoughTokens();

        FDPBContract.burn(
            msg.sender,
            FDPBContract.PBId(),
            spaceshipValue * amount
        );

        _mint(msg.sender, id, amount, "");
    }

    //changes withdraw address if needed.
    function changeWithdrawer(
        address newAddress
    ) external withdrawAddressCheck {
        withdrawAccount = newAddress;
    }

    //withdraws all eth funds.
    function withdrawFunds() external withdrawAddressCheck {
        (bool success, bytes memory _data) = payable(msg.sender).call{
            value: this.totalBalance()
        }("");
        if (!success) revert FailedToWithdraw();
    }

    //withdraws ERC20 tokens.
    function withdrawERC20(IERC20 erc20Token) external withdrawAddressCheck {
        erc20Token.transfer(msg.sender, erc20Token.balanceOf(address(this)));
    }

    //sets new baseURI
    function setURI(string calldata URI) external onlyOwner {
        _baseURI = URI;
    }

    function setName(string calldata newName) external onlyOwner {
        name = newName;
    }

    function uri(
        uint256 tokenId
    ) public view override(ERC1155) returns (string memory) {
        return
            string(
                abi.encodePacked(
                    _baseURI,
                    Strings.toString(tokenId),
                    string(".json")
                )
            );
    }
}

abstract contract FDPBContractTrait {
    function balanceOf(
        address account,
        uint256 tokenId
    ) external view virtual returns (uint256);

    function burn(address sender, uint256 id, uint256 amount) external virtual;

    function PBId() external view virtual returns (uint256);
}
