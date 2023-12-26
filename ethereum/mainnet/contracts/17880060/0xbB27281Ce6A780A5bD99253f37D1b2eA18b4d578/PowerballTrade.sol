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
error NotEnoughEth();
error PastBoundsOfBatchLimit();
error PastSupply();
error AlreadyMinted();
error AuthenticationFailed();
error DoesNotExist();
error NotEnoughCards();

contract FringePowerBall is ERC1155, Ownable {
    string public name = "Powerball - Fringe Drifters";
    string public symbol = "PBFD";

    address internal _FDCardContract;

    function changeCardContractAddress(
        address newContractAddress
    ) public onlyOwner {
        _FDCardContract = newContractAddress;
    }

    uint256 public PBId = 1;

    function changePBId(uint256 newId) public onlyOwner {
        PBId = newId;
    }

    address private withdrawAccount =
        0x8ff8657929a02c0E15aCE37aAC76f47d1F5fbfC6;

    address public transferAddress = 0x33f6864805eD3E88489B30EBa26B2320f561C1e6;

    function changeTransferAddress(address newAddress) public onlyOwner {
        transferAddress = newAddress;
    }

    mapping(uint256 => uint256) public CardValues;

    function changeCardValues(
        uint256 cardId,
        uint256 cardValue
    ) public onlyOwner {
        CardValues[cardId] = cardValue;
    }

    string internal _baseURI;

    //modifiers.
    modifier withdrawAddressCheck() {
        if (msg.sender != withdrawAccount) revert NotWithdrawAddress();
        _;
    }

    constructor(string memory baseURI) ERC1155("") {
        _baseURI = baseURI;
    }

    function tradeLootCardForPB(uint256 cardType, uint256 amount) external {
        FDCardContractTrait FDCardContract = FDCardContractTrait(
            _FDCardContract
        );

        if (FDCardContract.balanceOf(msg.sender, cardType) < amount)
            revert NotEnoughCards();

        FDCardContract.safeTransferFrom(
            msg.sender,
            transferAddress,
            cardType,
            amount,
            ""
        );

        uint256 cardValue = CardValues[cardType];

        if (cardValue == 0) revert DoesNotExist();

        _mint(msg.sender, PBId, cardValue * amount, "");
    }

    //gifts powerballs in bulk
    function gift(
        uint256 cardId,
        address[] calldata receivers,
        uint256[] calldata amounts
    ) external onlyOwner {
        for (uint256 i = 0; i < receivers.length; i++) {
            _mint(receivers[i], cardId, amounts[i], "");
        } //bulk mints.
    }

    function burn(address sender, uint256 id, uint256 amount) external {
        _burn(sender, id, amount);
    }

    function totalBalance() external view returns (uint256) {
        //gets total balance in account.
        return payable(address(this)).balance;
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

abstract contract FDCardContractTrait {
    function balanceOf(
        address account,
        uint256 tokenId
    ) external view virtual returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        uint256 amount,
        bytes memory data
    ) external virtual;
}
