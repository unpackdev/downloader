// Parrot Social Club
//
// Parrots gain you access to games and contests at the Parrot Social Club
// https://www.parrotsocial.club
//
//
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B?77J&@
// @@@@@@@@@@@@@@&&&&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@#7!!7B@@
// @@@@&#BG5YJJ???7777?J5G&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&?!!!5#G#
// @@@&J!!!!!7!!!!!75PPP5J?5&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@BPPJ!!!?5PB&
// @@@@G?J5G#B7!!!?B@@@@@@#?Y@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B5JJP&@@@@@GYY!!!7&@@@@
// @@@@@&@@@&?!!!J&@@@@@@@@57&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@B5GB&@@#PP&@@@@G?!!!7Y5??B@@@@G!!!5@@@@@
// @@@@@@@@&?!!!5@@@@@@@@@G75@@@@@&&@@@@@@@@@@@@5?J5B@@BYY#@@@B!!!7#@G7!7&@@&Y!!!7P&@@?!?&@@@J!!!B@@@@@
// @@@@@@@#?!!7G@@@@@&#GY77P@@@BY?77JB@##&@@@@@5!!!J&&5!!7&@@&?!!7##Y!!!7#@&?!!!J#@@@@Y!7#@@&7!!7&@@@@@
// @@@@@@G7!!!7YYJJ??7!7?P&@@BJ!!!7YPB5!!Y@@@@B!!!J&GJ!!!7#@@5!!!YPYBBJ7!P@Y!!!?&@@@@@J!?@@@#7!!?@@@@@@
// @@@@@P!!!JGY???JJYPB&@@@&Y!!!?P&@@Y!!?&@@@&7!!!YYP&#Y77B@#7!!!JB@@@@#B@&7!!7#@@@@@B!!B@@@&7!!7#@@&GG
// @@@@Y!!!Y@@@@@@@@@@@@@@#?!!!5&@@#J!!7#@@@@Y!!!?G@@@@@&&@@Y!!!5@@@@@@@@@#7!!J@@@@@G!?B@@@@#PJ7!?5YYB@
// @@&J!!!5@@@@@@@@@@@@@@&?!!7G@@@G?7!!P@@@@B!!!J&@@@@@@@@@#7!!Y@@@@@@@@@@@5!!7#@&GJ?P&@@@BJ7?Y##BB#@@@
// @B7!!!P@@@@@@@@@@@@@@@G!!!G@@#JY5!!7&@@@@?!!?&@@@@@@@@@@5!!7#@@@&&@@@@@@@BY?JYY5B@@@@@5!!!JB@@@@@@@@
// P!!!!5@@@@@@@@@@@@@@@@B!!7BGYJB@J!!7&@@@G!!!G@@@@@@@@@@@P?7J@@@&?7?P@@@@@@@@&&@@@@@@&J!!?B@@@@@@@@@@
// &57!Y@@@@@@@@@@@@@@@@@@BYJYP#@@@BYJYB@@@&G55@@@@@@@@@@@@@@&&@@@B!!Y#@@@@@@@@@@@@@@@#?!!5&@@@@@@@@@@@
// @@&#&@@@@@@@@@@@@@@#G5YJJ??JJJG@@@@@@@@@@@@@@@@@@@@@@&&&@@@@@@@@PB@@@@&BG#@@@@@@@@#?!!G@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@&5?!77?JJJJ?7~Y@@@@@@@@@&@@@@@@@@@B5J?Y5JB@@@B5G#@@@#Y7!!JBGYG@@@&?!7G@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@#7?5B&@@@@@@@&B&@@@@@@BY?7YGB&@@@BJ!!5&@G~5@@P!!!5@@P7!75#@5!!G@@@J!!G@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@Y!B@@@@@@@@@@@@@@@@@&Y!!75#P!J@@G!!7B@@#J5&@#7!!5@@5!!J&@&Y!!G@@@5!!5@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@#?7?JY5PGBB#&@@@@@@&?!!J&@@#!7&&7!!P@@@@@@@@P!!J@@B!!Y@@BJ7!Y@@@B!!J@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@BP5YJ??77777J5&@@Y!!J@@@@B!J@@?!!G@@@@##@@J!7#@@P!!B#55G!!G@@@5!!B@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@&&##BPJ?#@?!!B@@@#7?&@@#J!?##P5P&@@G7Y@@@&5?YP#@&YJP@@@G7?@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@&7P@P!!G@&P?5@@@@@@B555G&@@@@@&&@@@@@@@@@@@@@@@@@@#B@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@JYB&@@@@@@@@@#P?!#@@BYJ55G&@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@J!!7?JYYYYJJ7!!JB@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @@@@@@@@@@@@@@@&G5J?7!!!!7?JPB@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
pragma abicoder v1;

import "./Ownable.sol";
import "./ERC721A.sol";
import "./console.sol";

abstract contract ParrotPassContract {
    function ownerOf(uint256 tokenId) public view virtual returns (address);

    function balanceOf(address owner)
        external
        view
        virtual
        returns (uint256 balance);
}

contract ParrotSocialClub is ERC721A, Ownable {

    ParrotPassContract public PASS;

    uint256 public constant MAX_PARROTS = 8888;
    uint256 public constant MAX_RESERVED_PARROTS = 10;
    uint256 public passParrotsMinted = 0;
    uint256 public paidParrotsMinted = 0;
    uint256 public freeParrotsMinted = 0;

    address public vault;
    uint256 public price = 0.02 ether;
    uint256 public MAX_PAID_PARROTS = 4878;
    uint256 public MAX_PASS_PARROTS = 2000;
    uint256 public MAX_FREE_PARROTS = 2000;
    uint public MAX_FREE_PARROTS_PER_WALLET = 2;

    bool public mintPaused = true;

    string public baseURI;

    mapping (uint256 => bool) public claimedParrots;

    event MintedParrot(address claimer, uint256 amount);

    constructor()
        ERC721A('Parrot Social Club', 'PSC')
    {}

    function mint(uint256 numParrots) external payable {
        require(!mintPaused, 'Parrot minting paused.');
        require(
            numParrots > 0 && numParrots <= 20,
            'You can mint no more than 20 Parrots at a time.'
        );
        require(
            totalSupply() + numParrots <= MAX_PARROTS,
            'There are no more parrots available for minting.'
        );
        require(
            paidParrotsMinted + numParrots <= MAX_PAID_PARROTS,
            'There are no more parrots available for paid minting.'
        );
        require(
            msg.value >= price * numParrots,
            'Ether value sent is not sufficient'
        );
        require(tx.origin == msg.sender, 'Cant be called from another contract');


        _safeMint(msg.sender, numParrots);
        paidParrotsMinted += numParrots;

        emit MintedParrot(msg.sender, numParrots);
    }

        function freemint(uint256 numParrots) external payable {
        uint256 senderBalance = balanceOf(msg.sender);
        require(!mintPaused, 'Parrot minting paused.');
        require(
            numParrots > 0 && numParrots <= MAX_FREE_PARROTS_PER_WALLET,
            'You have exceeded the limit for free parrots.'
        );
        require(
            numParrots + senderBalance <= MAX_FREE_PARROTS_PER_WALLET,
            'You have exceeded the limit for free parrots.'
        );
        require(
            totalSupply() + numParrots <= MAX_PARROTS,
            'There are no more parrots available for minting.'
        );
        require(
            freeParrotsMinted + numParrots <= MAX_FREE_PARROTS,
            'There are no more parrots available for free minting.'
        );
        require(tx.origin == msg.sender, 'Cant be called from another contract');


        _safeMint(msg.sender, numParrots);
        freeParrotsMinted += numParrots;

        emit MintedParrot(msg.sender, numParrots);
    }


    function passClaim(uint256 passId) external {
        require(tx.origin == msg.sender, 'Cant be called from another contract');
        require(!mintPaused, 'Free Parrot minting paused.');
        require(!claimedParrots[passId], 'Pass has already claimed a parrot.');
        require(passId < MAX_PASS_PARROTS, 'Invalid Pass ID');
        require(
            PASS.ownerOf(passId) == msg.sender,
            'Need to own the pass youre claiming a parrot for.'
        );
        require(
            totalSupply() + 1 <= MAX_PARROTS,
            'There are no more parrots available for minting.'
        );
        require(
            passParrotsMinted + 1 <= MAX_PASS_PARROTS,
            'There are no more Parrots that can be claimed.'
        );
        passParrotsMinted++;
        claimedParrots[passId] = true;

        _safeMint(msg.sender, 1);
        emit MintedParrot(msg.sender, 1);
    }

    function passClaimMultiple(uint256[] calldata passIds) external {
        uint256 numParrots = passIds.length;
        require(tx.origin == msg.sender, 'Cant be called from another contract');
        require(!mintPaused, 'Free minting paused.');
        require(
            numParrots > 0 && numParrots <= 20,
            'You can mint no more than 20 Parrots at a time.'
        );
        require(
            totalSupply() + numParrots <= MAX_PARROTS,
            'There are no more parrots available for minting.'
        );
        require(
            passParrotsMinted + numParrots <= MAX_PASS_PARROTS,
            'There are no more Parrots that can be claimed.'
        );

        for (uint256 i = 0; i < numParrots; i++) {
            uint256 passId = passIds[i];
            require(passId < MAX_PASS_PARROTS, 'Invalid Pass ID');
            require(
                PASS.ownerOf(passId) == msg.sender,
                'Sender needs to own the pass to claim a parrot'
            );
            require(!claimedParrots[passId], 'Pass has already claimed a parrot');
        }

        passParrotsMinted += numParrots;
        for (uint256 i = 0; i < numParrots; i++) {
            uint256 passId = passIds[i];
            claimedParrots[passId] = true;
        }
        _safeMint(msg.sender, numParrots);

        emit MintedParrot(msg.sender, numParrots);
    }

    function tokenURI(uint256 _tokenId) public view override returns (string memory) {
        require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');
        return string(abi.encodePacked(baseURI, Strings.toString(_tokenId), '.json'));
    }
    

    function walletOfOwner(address _owner) public view returns (uint256[] memory) {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = _startTokenId();
        uint256 ownedTokenIndex = 0;
        address latestOwnerAddress;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId < _currentIndex) {
          TokenOwnership memory ownership = _ownerships[currentTokenId];

          if (!ownership.burned) {
            if (ownership.addr != address(0)) {
              latestOwnerAddress = ownership.addr;
            }

            if (latestOwnerAddress == _owner) {
              ownedTokenIds[ownedTokenIndex] = currentTokenId;

              ownedTokenIndex++;
            }
          }

          currentTokenId++;
        }

        return ownedTokenIds;
    }

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function isClaimed(uint256 passTokenId) external view returns (bool) {
        require(passTokenId < MAX_PASS_PARROTS, 'Invalid Pass ID');
        return claimedParrots[passTokenId];
    }

    /*
     * Only the owner can do these things
     */
    function setBaseURI(string memory newBaseURI) public onlyOwner {
        baseURI = newBaseURI;
    }

    function pause(bool val) public onlyOwner {
        mintPaused = val;
    }

    function withdraw() external onlyOwner {
        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, 'Transfer failed.');
    }

    function setDependentContract(address passContractAddress) public onlyOwner {
        PASS = ParrotPassContract(passContractAddress);
    }

    function setMintPrice(uint256 _newPrice) public onlyOwner {
        price = _newPrice;
    }

    function setPaidMint(uint256 _paidMint) external onlyOwner {
        MAX_PAID_PARROTS = _paidMint;
    }

    function setPassMint(uint256 _passMint) external onlyOwner {
        MAX_PASS_PARROTS = _passMint;
    }

    function setFreeMint(uint256 _freeMint) external onlyOwner {
        MAX_FREE_PARROTS = _freeMint;
    }

    function setMaxFree(uint256 _freeMintperwallet) external onlyOwner {
        MAX_FREE_PARROTS_PER_WALLET = _freeMintperwallet;
    }

    function reserve(uint256 numPasses) public onlyOwner {
        require(
            totalSupply() + numPasses <= MAX_RESERVED_PARROTS,
            'Exceeded reserved supply'
        );
        _safeMint(owner(), numPasses);
    }
}