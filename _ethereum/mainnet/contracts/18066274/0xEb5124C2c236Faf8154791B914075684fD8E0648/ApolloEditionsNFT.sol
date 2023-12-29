// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./IERC721A.sol";
import "./IDelegationRegistry.sol";

error EditionNotLive();
error NotEnoughCredits();
error NotTokenOwner();
error ApolloNotSet();
error InvalidInput();
error NotMinter();

interface WarmInterface {
    function getColdWallets(address hotWallet) external view returns (address[] memory);
}

contract ApolloEditionsNFT is ERC1155, Ownable {
    string private _baseURI;
    string private _contractURI = "ipfs://QmVG1tqvfuyFuBGwzWDtHMzqxuPc1Z7UtYHR8V6hRgdKV4";
    address public apolloNFT = 0x1bB602b7a2ef2aECBA8FE3Df4b501C4C567B697d;
    address public minterContract;
    address public delegateContract = 0x00000000000076A84feF008CDAbe6409d2FE638B;
    address public warmContract = 0xC3AA9bc72Bd623168860a1e5c6a4530d3D80456c;
    address public firstMinter = 0x31E0E16b46F5345ea8696B3f9C9083400aB1bE24;

    mapping(uint256 => bool) public liveEditions;
    mapping(uint256 => uint256) private _totalSupply;
    mapping(uint256 => uint256) public lastUsedPeriod;
    mapping(uint256 => uint256) public creditsRemaining;

    uint256 public currentPeriod = 1;
    uint256 public apolloCredits = 2;

    constructor(string memory baseURI) ERC1155(baseURI) {
        _baseURI = baseURI;
        _totalSupply[1] += 1;
        _mint(firstMinter, 1, 1, "");
    }

    modifier isMinterContract() {
        if (msg.sender != minterContract) {
            revert NotMinter();
        }
        _;
    }

    function setApolloNFT(address _apolloNFT) external onlyOwner {
        apolloNFT = _apolloNFT;
    }

    function setEditionLive(uint256 editionId, bool live) external onlyOwner {
        liveEditions[editionId] = live;
    }

    function setEditionsLive(uint256[] memory editionIds, bool live) external onlyOwner {
        for (uint256 i = 0; i < editionIds.length; i++) {
            liveEditions[editionIds[i]] = live;
        }
    }

    function setMinterContract(address newMinterContract) external onlyOwner {
        minterContract = newMinterContract;
    }

    function setURI(string memory newuri) external onlyOwner {
        _baseURI = newuri;
    }

    function setContractURI(string memory newuri) external onlyOwner {
        _contractURI = newuri;
    }

    function setApolloCredits(uint256 newApolloCredits) external onlyOwner {
        apolloCredits = newApolloCredits;
    }

    function setDelegateContract(address newDelegateContract) external onlyOwner {
        delegateContract = newDelegateContract;
    }

    function setWarmContract(address newWarmContract) external onlyOwner {
        warmContract = newWarmContract;
    }

    function incrementPeriod() external onlyOwner {
        currentPeriod++;
    }

    function uri(uint256) public view override returns (string memory) {
        return _baseURI;
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function totalSupply(uint256 editionId) public view returns (uint256) {
        return _totalSupply[editionId];
    }

    function getCreditsRemaining(uint256[] memory apolloIds) public view returns (uint256[] memory) {
        if (apolloNFT == address(0)) revert ApolloNotSet();

        IERC721A apolloContract = IERC721A(apolloNFT);

        uint256[] memory _creditsRemaining = new uint256[](apolloIds.length);

        for (uint256 i = 0; i < apolloIds.length; i++) {
            if (apolloIds[i] > apolloContract.totalSupply()) {
                _creditsRemaining[i] = 0;
            } else if (apolloContract.totalSupply() == 0) {
                _creditsRemaining[i] = 0;
            } else if (lastUsedPeriod[apolloIds[i]] < currentPeriod) {
                _creditsRemaining[i] = apolloCredits;
            } else {
                _creditsRemaining[i] = creditsRemaining[apolloIds[i]];
            }
        }

        return _creditsRemaining;
    }

    function mint(uint256[][2] memory editionIds, uint256[][2] memory apolloIds, address[] memory vaults) public {
        if (editionIds[0].length != editionIds[1].length) revert InvalidInput();

        uint256 editionsSum = 0;
        for (uint256 i = 0; i < editionIds[1].length; i++) {
            editionsSum += editionIds[1][i];
        }

        uint256 apolloSum = 0;
        for (uint256 i = 0; i < apolloIds[1].length; i++) {
            apolloSum += apolloIds[1][i];
        }

        if (apolloSum != editionsSum) revert InvalidInput();

        verifyOwnership(apolloIds[0], vaults);
        uint256[] memory _remainingCredits = getCreditsRemaining(apolloIds[0]);

        for (uint256 i = 0; i < apolloIds[0].length; i++) {
            if (_remainingCredits[i] < apolloIds[1][i]) revert NotEnoughCredits();
            if (lastUsedPeriod[apolloIds[0][i]] < currentPeriod) {
                lastUsedPeriod[apolloIds[0][i]] = currentPeriod;
            }
            creditsRemaining[apolloIds[0][i]] = _remainingCredits[i] - apolloIds[1][i];
        }

        for (uint256 i = 0; i < editionIds[0].length; i++) {
            if (!liveEditions[editionIds[0][i]]) revert EditionNotLive();
            _totalSupply[editionIds[0][i]] += editionIds[1][i];
            _mint(msg.sender, editionIds[0][i], editionIds[1][i], "");
        }
    }

    function contractMint(address recepient, uint256[][2] memory editionIds) public isMinterContract {
        if (editionIds[0].length != editionIds[1].length) revert InvalidInput();

        for (uint256 i = 0; i < editionIds[0].length; i++) {
            if (!liveEditions[editionIds[0][i]]) revert EditionNotLive();
            _totalSupply[editionIds[0][i]] += editionIds[1][i];
            _mint(recepient, editionIds[0][i], editionIds[1][i], "");
        }
    }

    function verifyOwnership(uint256[] memory apolloIds, address[] memory vaults) public view {
        IERC721A apolloContract = IERC721A(apolloNFT);
        IDelegationRegistry delegateInterface = IDelegationRegistry(delegateContract);

        for (uint256 i = 0; i < apolloIds.length; i++) {
            bool verified = false;
            if (apolloContract.ownerOf(apolloIds[i]) == msg.sender) {
                verified = true;
            }

            if (verified == false && delegateContract != address(0)) {
                for (uint256 vaultsI = 0; vaultsI < vaults.length; vaultsI++) {
                    if (
                        delegateInterface.checkDelegateForToken(
                            msg.sender, vaults[vaultsI], address(apolloContract), apolloIds[i]
                        ) == true
                    ) {
                        verified = true;
                        vaultsI = vaults.length;
                    }
                }
            }

            if (verified == false && warmContract != address(0)) {
                address[] memory coldWallets = WarmInterface(warmContract).getColdWallets(msg.sender);
                for (uint256 coldI = 0; coldI < coldWallets.length; coldI++) {
                    if (apolloContract.ownerOf(apolloIds[i]) == coldWallets[coldI]) {
                        verified = true;
                        coldI = coldWallets.length;
                    }
                }
            }

            if (verified == false) revert NotTokenOwner();
        }
    }
}
