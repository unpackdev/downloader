// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "./ERC721.sol";
import "./ReentrancyGuard.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./IAntiRunnersRenderer.sol";
import "./IChainRunners.sol";
import "./console.sol";

//    _____                 _____                         
//   (, /  |          ,    (, /   )                       
//     /---| __  _/_         /__ /    __  __    _  __  _  
//  ) /    |_/ (_(___(_   ) /   \_(_(_/ (_/ (__(/_/ (_/_)_
// (_/                   (_/                              
//
//  10,000 NFT's generated mainly from the original 10,000 Chainrunners.
//  Each Anti Runner has a sibling Chain Runner.  When re-united with its
//  sibling, fun things happen.                            
//
//  This is the ERC721 implementation for Anti Runners. Here we provide
//  the ability to mint a new Anti Runner and handle revenue disbursement
//  amongst the Chainrunner and Blitmap teams.
//

contract AntiRunners is ERC721, Ownable, ReentrancyGuard {
    address public chainRunnersAddress;
    address public renderingContractAddress;

    using Counters for Counters.Counter;
    Counters.Counter public tokensMinted;

    uint256 private constant MAX_RUNNERS = 10_000;
    uint256 private constant MINT_PRICE = 0.05 ether;

    mapping(address => uint256) private numClaimedAtDiscount;

    uint256 private runnerZeroHash;
    uint256 private runnerZeroDNA;

    uint256 public earlyAccessStartTimestamp;
    uint256 public publicSaleStartTimestamp;

    mapping(address => uint256) private withdrawalAllotment1000th;
    mapping(address => uint256) private withdrawedAmount;
    uint256 private totalWithdrawed;

    constructor(address payable _chainRunnersAddress) ERC721("Anti Runners", "ANTI") {
        chainRunnersAddress = _chainRunnersAddress;
        
        withdrawalAllotment1000th[msg.sender] = 700;                                             // 70%  - Anti Runners Team
        withdrawalAllotment1000th[address(0x44A2ee3bB45d002157d2508C1003A4e055D52Bc8)] = 150;    // 15%  - Chain Runners Team
        withdrawalAllotment1000th[address(0xF296178d553C8Ec21A2fBD2c5dDa8CA9ac905A00)] = 71;     // 7.1% - Dom
        withdrawalAllotment1000th[address(0xE7bd51Dc30d4bDc9FDdD42eA7c0a283590C9D416)] = 1;      // 0.1% - jstn
        withdrawalAllotment1000th[address(0x9BC20560301cDc15c3190f745B6D910167d4b467)] = 1;      // 0.1% - bhoka
        withdrawalAllotment1000th[address(0xC5fFbCd8A374889c6e95f8df733e32A0e9476a9c)] = 11;     // 1.1% - BRAINDRAIND
        withdrawalAllotment1000th[address(0x8e29B3F71a8c7276d122C88d9bf317e857ABb376)] = 12;     // 1.2% - BigPapap
        withdrawalAllotment1000th[address(0x9Bf043a72ca1cD3DC4BCa66c9F6c1d040CfF7772)] = 12;     // 1.2% - Veenus
        withdrawalAllotment1000th[address(0xBb01f3CAc350eD60B1bD080B7A55cC5768cFD565)] = 4;      // 0.4% - startselect
        withdrawalAllotment1000th[address(0xf0136dEe223c9a303ae8863F9438a687C775a4a7)] = 2;      // 0.2% - pinot
        withdrawalAllotment1000th[address(0xd1e0eb60Bda1c098353D08a167B011EA8bcd38Fa)] = 4;      // 0.4% - zod
        withdrawalAllotment1000th[address(0x4610CC9c73C0215818fE47962eaBD93cF331856b)] = 4;      // 0.4% - KlingKlong
        withdrawalAllotment1000th[address(0xd42bd96B117dd6BD63280620EA981BF967A7aD2B)] = 10;     // 1.0% - numo
        withdrawalAllotment1000th[address(0xeE463034F385DD9B26efD7767406079f86edB992)] = 4;      // 0.4% - themoonladder
        withdrawalAllotment1000th[address(0x9f2942fF27e40445d3CB2aAD90F84C3a03574F26)] = 2;      // 0.2% - askywlkr
        withdrawalAllotment1000th[address(0x48A63097E1Ac123b1f5A8bbfFafA4afa8192FaB0)] = 2;      // 0.2% - ceresstation
        withdrawalAllotment1000th[address(0x6EBd8991fC87F130DE28DE4b37F882d6cbE9aB28)] = 4;      // 0.4% - HighleyVarlet
        withdrawalAllotment1000th[address(0xfB843f8c4992EfDb6b42349C35f025ca55742D33)] = 1;      // 0.1% - worm
        withdrawalAllotment1000th[address(0x06Ac1F9f86520225b73EFCe4982c9d9505753251)] = 1;      // 0.1% - hipcityreg
        withdrawalAllotment1000th[address(0xf4c9C5229356d39b4F852ecF6E08576EebEDB0EC)] = 4;      // 0.4% - spacedoctor
    }

    function setRenderingContractAddress(address _renderingContractAddress) public onlyOwner {
        renderingContractAddress = _renderingContractAddress;
    }

    function mintRunnersAtFullPrice(uint256 _count) external payable nonReentrant returns (uint256, uint256) {
        require(_count * MINT_PRICE == msg.value, "Incorrect amount of ether sent");
        return mintRunners(_count);
    }

    function mintRunnersAtDiscount(uint256 _count) external payable nonReentrant returns (uint256, uint256) {
        require(_count * MINT_PRICE / 2 == msg.value, "Incorrect amount of ether sent");

        uint256 allowedLeft = allowedLeftAtDiscount(msg.sender);
        require(_count <= allowedLeft, "Not enough allowed at discount.");

        numClaimedAtDiscount[msg.sender] += _count;

        return mintRunners(_count);
    }

    function mintRunners(uint256 _count) internal returns (uint256, uint256) {
        require(_count > 0, "Invalid amount");
        require(tokensMinted.current() + _count <= MAX_RUNNERS, "All Runners have been minted");

        uint256 firstMintedId = MAX_RUNNERS - tokensMinted.current();

        for (uint256 i = 0; i < _count; i++) {
            _safeMint(msg.sender, MAX_RUNNERS - tokensMinted.current());
            tokensMinted.increment();
        }

        return (firstMintedId, _count);
    }

    function allowedAtDiscount(address _addr) public view returns (uint256) {
        return IChainRunners(chainRunnersAddress).balanceOf(_addr);
    }

    function claimedAtDiscount(address _addr) public view returns (uint256) {
        return numClaimedAtDiscount[_addr];
    }

    function allowedLeftAtDiscount(address _addr) public view returns (uint256) {
        uint256 allowedLeft = allowedAtDiscount(_addr) - claimedAtDiscount(_addr);

        if (allowedLeft > 0) {
            return allowedLeft;
        }

        return 0;
    }

    function mintRunnerZero() external {
        require(runnerZeroHash != 0, "Runner Zero has not been configured");
        require(!_exists(0), "Runner Zero has already been minted");
        require(IChainRunners(chainRunnersAddress).getDna(0) != 0, "Chain Runner 0 does not exist");

        _safeMint(msg.sender, 0);
    }

    function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (renderingContractAddress == address(0)) {
            return '';
        }

        bool isReunited = IChainRunners(chainRunnersAddress).ownerOf(_tokenId) == ownerOf(_tokenId);

        IAntiRunnersRenderer renderer = IAntiRunnersRenderer(renderingContractAddress);
        return renderer.tokenURI(IAntiRunnersRenderer.TokenURIInput(_tokenId, getDna(_tokenId), isReunited));
    }

    function tokenURIForSeed(uint256 _tokenId, uint256 seed, bool isReunited) public view virtual returns (string memory) {
        if (renderingContractAddress == address(0)) {
            return '';
        }

        IAntiRunnersRenderer renderer = IAntiRunnersRenderer(renderingContractAddress);
        return renderer.tokenURI(IAntiRunnersRenderer.TokenURIInput(_tokenId, seed, isReunited));
    }

    function tokenSVG(uint256 _tokenId) public view virtual returns (string memory) {
        require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

        if (renderingContractAddress == address(0)) {
            return '';
        }

        bool isReunited = IChainRunners(chainRunnersAddress).ownerOf(_tokenId) == ownerOf(_tokenId);

        IAntiRunnersRenderer renderer = IAntiRunnersRenderer(renderingContractAddress);
        return renderer.tokenSVG(getDna(_tokenId), isReunited);
    } 

    function getDna(uint256 _tokenId) public view returns (uint256) {
        return IChainRunners(chainRunnersAddress).getDna(_tokenId);
    }

    receive() external payable {}

    function withdraw() public nonReentrant {
        require(withdrawalAllotment1000th[msg.sender] > 0, "Not allowed to withdraw.");

        uint256 amount = allowedWithdrawalAmount(msg.sender);
        require(amount > 0, "Amount must be positive.");

        withdrawedAmount[msg.sender] += amount;
        totalWithdrawed += amount;
        (bool success,) = msg.sender.call{value : amount}('');
        require(success, "Withdrawal failed.");
    }

    function allowedWithdrawalAmount(address _addr) public view returns (uint256) {
        uint256 allotment1000th = withdrawalAllotment1000th[_addr];
        uint256 total = address(this).balance + totalWithdrawed;
        uint256 amount = total * allotment1000th / 1000 - withdrawedAmount[_addr];
        return amount;
    }
}
