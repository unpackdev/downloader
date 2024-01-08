// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "./Ownable.sol";
import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./ERC721Pausable.sol";
import "./Context.sol";
import "./ReentrancyGuard.sol";

error CCAonlyOwnerAllowedToCall();

error CCATryMintZeroTokens();

error CCAAmountMoreThenMaxMintAmount();

error CCAAfterMintTotalSupplyMoreThenMaxTotalSupply();

error CCASaleIsNotStartedYet();

error CCASaleIsEnd();

error CCANotEnoughMoney();

error CCAChangeNotSend();

error CCASenderIsNotEligibleForPresale();

error CCAGasRefundNotSendForOG();

error CCAStatusIsNotReveal();

error CCARevealIsLastWorkflowStep();

error CCATeamAllocationHasAlreadyBeen();

error CCANotEnoughMoneyForWithdraw(uint256 balance);

error CCAWithdrawNotSend();

error LateForTeamAllocation();

contract CyberCatsAlliance is Context, ERC721Enumerable, ERC721Pausable, ReentrancyGuard, Ownable {
    enum Workflow {
        Before,
        Presale,
        Sale,
        Reveal
    }

    Workflow public workflowStatus;

    uint256 public constant GAS_PRICE_FOR_THE_TRANSFER = 21000;

    uint256 public maxTotalSupply = 2222;
    uint256 public maxMintAmount = 20;
    uint256 public allocationNFTforTeam = 50;
    uint256 public presalePriceWL = 0.07 ether;
    uint256 public presalePriceOG = 0.07 ether;
    uint256 public publicPrice = 0.08 ether;
    uint256 public maxGasPriceForRefund = 100 gwei;
    string public placeHolderUri;
    string public baseTokenUri;
    bool public teamAllocationAlready;
    mapping(address => bool) public listWL;
    mapping(address => bool) public listOG;

    event Withdrawal(uint256 amount);
    event Received(address user, uint256 amount);

    constructor(string memory _placeHolderURI) ERC721("Cyber Cats Alliance", "CCA") {
        placeHolderUri = _placeHolderURI;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) external nonReentrant onlyOwner {
        if (address(this).balance < amount) {
            revert CCANotEnoughMoneyForWithdraw(address(this).balance);
        }
        (bool success, ) = _msgSender().call{value: amount}("");
        if (!success) {
            revert CCAWithdrawNotSend();
        }
        emit Withdrawal(amount);
    }

    function addToListWL(address[] memory userList) external onlyOwner {
        for (uint256 i = 0; i < userList.length; i++) {
            listWL[userList[i]] = true;
        }
    }

    function addToListOG(address[] memory userList) external onlyOwner {
        for (uint256 i = 0; i < userList.length; i++) {
            listOG[userList[i]] = true;
        }
    }

    function deleteWL(address[] calldata userList) external onlyOwner {
        for (uint256 i = 0; i < userList.length; i++) {
            delete listWL[userList[i]];
        }
    }

    function deleteOG(address[] calldata userList) external onlyOwner {
        for (uint256 i = 0; i < userList.length; i++) {
            delete listOG[userList[i]];
        }
    }

    function teamAllocation() external onlyOwner {
        if (workflowStatus > Workflow.Before) {
            revert LateForTeamAllocation();
        }
        if (teamAllocationAlready) {
            revert CCATeamAllocationHasAlreadyBeen();
        }
        teamAllocationAlready = true;
        for (uint256 i = 0; i < allocationNFTforTeam; i++) {
            _safeMint(msg.sender, totalSupply());
        }
    }

    function setPlaceHolderUri(string memory _uri) external onlyOwner {
        placeHolderUri = _uri;
    }

    function setMaxTotalSupply(uint256 _maxTotalSupply) external onlyOwner {
        maxTotalSupply = _maxTotalSupply;
    }

    function setMaxMintAmount(uint256 _maxMintAmount) external onlyOwner {
        maxMintAmount = _maxMintAmount;
    }

    function setAllocationNFTforTeam(uint256 _allocationNFTforTeam) external onlyOwner {
        allocationNFTforTeam = _allocationNFTforTeam;
    }

    function setPresalePriceWL(uint256 _presalePriceWL) external onlyOwner {
        presalePriceWL = _presalePriceWL;
    }

    function setPresalePriceOG(uint256 _presalePriceOG) external onlyOwner {
        presalePriceOG = _presalePriceOG;
    }

    function setPublicPrice(uint256 _publicPrice) external onlyOwner {
        publicPrice = _publicPrice;
    }

    function setMaxGasPriceForRefund(uint256 _maxGasPriceForRefund) external onlyOwner {
        maxGasPriceForRefund = _maxGasPriceForRefund;
    }

    function nextWorkflowStep() external onlyOwner {
        if (workflowStatus == Workflow.Reveal) {
            revert CCARevealIsLastWorkflowStep();
        }
        workflowStatus = Workflow(uint8(workflowStatus) + 1);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function mint(uint256 amount) external payable nonReentrant whenNotPaused {
        uint256 _gasLeftStart = gasleft();
        uint256 _priceToken;
        if (workflowStatus < Workflow.Presale) {
            revert CCASaleIsNotStartedYet();
        } else if (workflowStatus > Workflow.Sale) {
            revert CCASaleIsEnd();
        } else if (workflowStatus == Workflow.Presale) {
            if (hasOG(_msgSender())) {
                _priceToken = presalePriceOG;
            } else if (hasWL(_msgSender())) {
                _priceToken = presalePriceWL;
            } else {
                revert CCASenderIsNotEligibleForPresale();
            }
        } else {
            _priceToken = publicPrice;
        }

        if (amount == 0) {
            revert CCATryMintZeroTokens();
        }
        if (amount > maxMintAmount) {
            revert CCAAmountMoreThenMaxMintAmount();
        }
        if (tokensLeftToMint() < amount) {
            revert CCAAfterMintTotalSupplyMoreThenMaxTotalSupply();
        }
        if (msg.value < (amount * _priceToken)) {
            revert CCANotEnoughMoney();
        }
        for (uint256 i = 0; i < amount; i++) {
            _safeMint(_msgSender(), totalSupply());
        }
        uint256 change = msg.value - (amount * _priceToken);
        bool success;
        if (change > 0) {
            (success, ) = _msgSender().call{value: change}("");
            if (!success) {
                revert CCAChangeNotSend();
            }
        }
        if (workflowStatus == Workflow.Presale && hasOG(_msgSender()) && (tx.gasprice <= maxGasPriceForRefund)) {
            (success, ) = _msgSender().call{
                value: (_gasLeftStart - gasleft() + GAS_PRICE_FOR_THE_TRANSFER) * tx.gasprice
            }("");
            if (!success) {
                revert CCAGasRefundNotSendForOG();
            }
        }
    }

    function reveal(string memory _uri) public onlyOwner {
        if (workflowStatus != Workflow.Reveal) {
            revert CCAStatusIsNotReveal();
        }
        baseTokenUri = _uri;
    }

    function hasWL(address user) public view returns (bool) {
        return listWL[user];
    }

    function hasOG(address user) public view returns (bool) {
        return listOG[user];
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function tokensLeftToMint() public view returns (uint256) {
        return (maxTotalSupply - totalSupply());
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (workflowStatus == Workflow.Reveal) {
            return super.tokenURI(tokenId);
        }
        return placeHolderUri;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Enumerable, ERC721Pausable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return baseTokenUri;
    }
}
