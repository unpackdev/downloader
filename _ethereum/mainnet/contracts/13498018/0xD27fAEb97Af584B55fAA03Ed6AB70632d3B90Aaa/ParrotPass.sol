// Parrot Passes
//
// 8888 Parrot Pass NFTs
// https://www.parrotpasses.com
//
//
// SPDX-License-Identifier: MIT
pragma solidity ^0.7.3;
pragma experimental ABIEncoderV2;

import "./ERC721Burnable.sol";
import "./Ownable.sol";
import "./IERC20.sol";

contract ParrotPass is ERC721Burnable, Ownable {
    using SafeMath for uint256;
    using SafeMath for uint8;
    uint256 public constant MAX_PARROT_PASSES = 8888;
    uint256 public constant MAX_FREE_PASSES_PER_ROUND = 1000;
    uint256 public constant MAX_PAID_MINT = 4800;

    bool public mintPaused = true;
    bool public freeMintPaused = true;

    IERC721[] public currentFreeMintTokens;

    address public vault;
    uint256 public price = 2 * 10**16; //0.02 ETH;

    uint256 public freePassesMinted = 0;
    uint256 public paidPassesMinted = 0;

    mapping (address => bool) public claimedFreePass;

    constructor(string memory name, string memory symbol)
        ERC721(name, symbol)
    {}

    function mint(uint256 numPasses) public payable {
        require(!mintPaused, 'ParrotPass minting paused.');
        require(
            numPasses > 0 && numPasses <= 3,
            'You can mint no more than 3 Parrot Passes at a time.'
        );
        require(
            totalSupply().add(numPasses) <= MAX_PARROT_PASSES,
            'Not enough ParrotPasses left for minting, try reducing the amount you want.'
        );
        require(
            paidPassesMinted.add(numPasses) <= MAX_PAID_MINT,
            'Not enough paid passes left for minting.'
        );
        require(
            msg.value >= price.mul(numPasses),
            'Ether value sent is not sufficient'
        );

        for (uint256 i = 0; i < numPasses; i++) {
            paidPassesMinted++;
            uint256 mintIndex = totalSupply();
            _safeMint(msg.sender, mintIndex);
        }
    }

    // one free token per wallet
    function freeMint() public payable {
        require(!freeMintPaused, 'Free ParrotPass minting paused.');
        require(!claimedFreePass[msg.sender], 'Address has already claimed a free parrot pass.');
        require(
            totalSupply().add(1) <= MAX_PARROT_PASSES,
            'Not enough passes left for minting.'
        );
        require(
            freePassesMinted.add(1) <= MAX_FREE_PASSES_PER_ROUND,
            'Not enough free passes left in this round of minting.'
        );
        bool walletHasFreeMintToken = false;
        for (uint256 i=0; i<currentFreeMintTokens.length; i++) {
            if (currentFreeMintTokens[i].balanceOf(msg.sender) >= 1) {
                walletHasFreeMintToken = true;
                break;
            }
        }
        require(
            walletHasFreeMintToken,
            'You dont own any of the tokens needed to claim a free ParrotPass.'
        );
        freePassesMinted++;
        if (freePassesMinted >= MAX_FREE_PASSES_PER_ROUND) {
            freeMintPaused = true;
            freePassesMinted = 0;
            delete currentFreeMintTokens;
        }
        claimedFreePass[msg.sender] = true;

        uint256 mintIndex = totalSupply();
        _safeMint(msg.sender, mintIndex);
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }

    function walletCanFreeMint(address _wallet)
        external
        view
        returns (bool canFreeMint)
    {
        bool canMint = false;
        if (claimedFreePass[_wallet]) {
            return canMint;
        }
        for (uint256 i=0; i<currentFreeMintTokens.length; i++) {
            if (currentFreeMintTokens[i].balanceOf(_wallet) >= 1) {
                canMint = true;
                break;
            }
        }
        return canMint;
    }

    /*
     * Only the owner can do these things
     */
    function setBaseURI(string memory _newBaseURI) public onlyOwner {
        _setBaseURI(_newBaseURI);
    }

    function addFreeMintToken(address _newTokenAddress) public onlyOwner {
        currentFreeMintTokens.push(IERC721(_newTokenAddress));
    }

    function clearFreeMintTokens() public onlyOwner {
        delete currentFreeMintTokens;
    }

    function pause(bool val) public onlyOwner {
        mintPaused = val;
        freeMintPaused = val;
    }

    function startNextFreeMintingRound() public onlyOwner {
        freePassesMinted = 0;
        freeMintPaused = false;
    }

    function setVault(address _newVaultAddress) public onlyOwner {
        vault = _newVaultAddress;
    }

    function withdraw(uint256 _amount) public onlyOwner {
        require(address(vault) != address(0), 'no vault');
        require(payable(vault).send(_amount));
    }

    function withdrawAll() public payable onlyOwner {
        require(address(vault) != address(0), 'no vault');
        require(payable(vault).send(address(this).balance));
    }

    function forwardERC20s(IERC20 _token, uint256 _amount) public onlyOwner {
        require(address(vault) != address(0));
        _token.transfer(vault, _amount);
    }

    function reserve(uint256 _numPasses) public onlyOwner {
        uint256 currentSupply = totalSupply();
        require(
            totalSupply().add(_numPasses) <= 88,
            'Exceeded reserved supply'
        );
        uint256 index;
        for (index = 0; index < _numPasses; index++) {
            _safeMint(owner(), currentSupply + index);
        }
    }

    function renounceOwnership() public override onlyOwner {}
}




