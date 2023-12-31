// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

// █▀ █▀▀   █▄▄ █▄█   █▀█ █▀█ █▀▀ █▀▄▀█ ▄▀█ ▀▄▀
// ▄█ █▄▄   █▄█ ░█░   █▀▄ █▀▀ █▄█ █░▀░█ █▀█ █░█

import "./ERC1155.sol";
import "./IERC721.sol";
import "./Ownable.sol";
import "./ERC1155Supply.sol";
import "./ReentrancyGuard.sol";
import "./Pausable.sol";
import "./ERC2981.sol";
import "./MerkleProof.sol";

contract AristoSpecialEdition is ERC1155, ERC2981, Pausable, Ownable, ReentrancyGuard, ERC1155Supply {

    string public name = "Aristo Special Edition";
    string public symbol = "ARISTOSPECIAL";

    struct Token {
        uint256 maxSupply;
        address[] ISC;
        bytes32 merkleTreeRoot;
        string URI;
        bool isURILocked;
        mapping (address => mapping (uint256 => bool)) usedISCTokens;
        mapping(address => uint256) mintedByAddress;
    }

    mapping(uint256 => Token) public tokens;

    uint256 public nextTokenID = 1;

    constructor() ERC1155("") {
        _setDefaultRoyalty(0x220639868D2947E8e336A109b7531ed87662b276, 1000); // Royalties par défaut fixées à 10%
    }

    // [O] Permet de switch la mise en pause du SC
    function pause() public onlyOwner { _pause(); }
    function unpause() public onlyOwner { _unpause(); }

    // [O] Permet de définir l'URI d'un token donné (pour ajout ultérieur)
    function setTokenURI(uint256 _tokenID, string memory _newuri) public onlyOwner {
        require(_tokenID >= 1 && _tokenID < nextTokenID, "Oh no, incorrect token ID :/");
        require(!tokens[_tokenID].isURILocked, "Hey, URI is locked !");
        tokens[_tokenID].URI = _newuri;
    }

    // [O] Permet de verrouiller l'URI d'un token donné
    function lockTokenURI(uint256 _tokenID) public onlyOwner {
        require(_tokenID >= 1 && _tokenID < nextTokenID, "Oh no, incorrect token ID :/");
        require(!tokens[_tokenID].isURILocked, "Hey, URI is locked !");
        tokens[_tokenID].isURILocked = true;
    }

    // [O] Ajoute un nouveau token mintable
    function addToken(uint256 _maxSupply, address[] memory _ISC, bytes32 _merkleTreeRoot, string memory _URI) public onlyOwner {
        Token storage newToken = tokens[nextTokenID];
        newToken.maxSupply = _maxSupply;
        newToken.URI = _URI;
        newToken.merkleTreeRoot = _merkleTreeRoot;
        for(uint sc = 0; sc < _ISC.length; sc++) {
            newToken.ISC.push(_ISC[sc]);
        }
        nextTokenID++;
    }

    // [O] Met à jour un token mintable
    function updateToken(uint256 _tokenID, uint256 _maxSupply, address[] memory _ISC, bytes32 _merkleTreeRoot) public onlyOwner {
        require(_tokenID >= 1 && _tokenID < nextTokenID, "Oh no, incorrect token ID :/");
        Token storage tokenToUpdate = tokens[_tokenID];
        tokenToUpdate.maxSupply = _maxSupply;
        tokenToUpdate.merkleTreeRoot = _merkleTreeRoot;
        delete tokenToUpdate.ISC;
        for(uint sc = 0; sc < _ISC.length; sc++) {
            tokenToUpdate.ISC.push(_ISC[sc]);
        }
    }

    // [P] Permet de mint avec prérequis de token "Genesis" et en quantité fixée (1)
    function mint(uint256 _tokenID, uint256 _genesisTokenID, bytes memory _data) public whenNotPaused {
        Token storage currentToken = tokens[_tokenID]; // Bascule en storage pour optimisation
        require(totalSupply(_tokenID) + 1 <= currentToken.maxSupply, "Oh no, supply overrun :/");

        bool isOwnerOfISC = false;
        bool isGenesisTokenIDUsed = false;
        address userISC;

        for(uint sc = 0; sc < currentToken.ISC.length; sc++) { // On boucle sur les différentes SC interfacés
            if (currentToken.usedISCTokens[currentToken.ISC[sc]][_genesisTokenID]) {
                isGenesisTokenIDUsed = true;
                continue; // Si l'utilisateur a déjà mint pour le SC en cours, on passe au SC suivant
            }

            try IERC721(currentToken.ISC[sc]).ownerOf(_genesisTokenID) returns (address tokenOwner) {
                if (tokenOwner == msg.sender) { // L'utilisateur est bien owner du SC en cours
                    isOwnerOfISC = true;
                    isGenesisTokenIDUsed = false;
                    userISC = currentToken.ISC[sc]; // Récupération de l'adresse du SC
                    break; // On sort de la boucle
                }
            } catch { }
        }
        
        // Sinon on s'assure qu'il est bien holder + que le NFT concerné n'a jamais été utilisé auparavant
        require(!isGenesisTokenIDUsed, "Oh no, token already used :/");
        require(isOwnerOfISC, "Hey, you aren't holder :/");
        currentToken.usedISCTokens[userISC][_genesisTokenID] = true; // Tracking token utilisé, rattaché à l'adresse du SC concerné
        _mint(msg.sender, _tokenID, 1, _data); // Mint time !
    }

    // [P] Permet de mint avec prérequis de WL, en quantité définie en amont (snapshot)
    function mintExt(uint256 _tokenID, uint256 _amount, uint256 _maxMints, bytes32[] calldata _proof, bytes memory _data) public whenNotPaused {
        Token storage currentToken = tokens[_tokenID]; // Bascule en storage pour optimisation
        require(_amount >= 1, "Really ?");
        require(totalSupply(_tokenID) + _amount <= currentToken.maxSupply, "Oh no, supply overrun :/");

        require(_verify(msg.sender, _maxMints, _proof, currentToken.merkleTreeRoot), "Hey, you aren't on the allowlist :/");
        require((_maxMints - currentToken.mintedByAddress[msg.sender]) >= _amount, "Hey, it's too much for you !");
        
        currentToken.mintedByAddress[msg.sender] += _amount; // Tracking mints effectués par adresse
        _mint(msg.sender, _tokenID, _amount, _data); // Mint time !
    }

    // [I] Permet de vérifier qu'une adresse est WL
    function _verify(address _userAddress, uint256 _mints, bytes32[] memory _proof, bytes32 _root) internal pure returns (bool) {
        return MerkleProof.verify(_proof, _root, keccak256(abi.encodePacked(_userAddress, _mints)));
    }

    // [O] Permet de mint une quantité souhaitée pour chaque token, sans prérequis, uniquement par l'owner du SC
    function mintBatch(address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data) public onlyOwner {
        _mintBatch(_to, _ids, _amounts, _data);
    }

    // [O] Permet d'airdrop un token vers de multiples adresses, sans prérequis, uniquement par l'owner du SC
    function airdrop(address[] memory _recipients, uint256 _tokenId, bytes memory _data) public onlyOwner {
        for (uint to = 0; to < _recipients.length; to++) { _mint(_recipients[to], _tokenId, 1, _data); }
    }
    
    // [P] Retourne les différents SC interfacés pour un token donné
    function getISCAddresses(uint256 _tokenID) public view returns (address[] memory) {
        return tokens[_tokenID].ISC;
    }

    // [P] Retourne le nombre de tokens mintés par une adresse pour un token donné
    function getMintedTokensByAddress(uint256 _tokenID, address _userAddress) public view returns (uint256) {
        return tokens[_tokenID].mintedByAddress[_userAddress];
    }

    // [P] Retourne le statut d'utilisation d'un token pour un SC d'un token donné
    function isUsedISCTokens(uint256 _tokenID, address _iscAddress, uint256 _iscTokenId) public view returns (bool) {
        return tokens[_tokenID].usedISCTokens[_iscAddress][_iscTokenId];
    }

    // [P] Retourne l'URI d'un token, générale ou spécifique si existante
    function uri(uint256 _tokenID) public view override returns (string memory) {
        require(_tokenID >= 1 && _tokenID < nextTokenID, "Oh no, incorrect token ID :/");
        string memory _tokenURI = tokens[_tokenID].URI;
        return bytes(_tokenURI).length > 0 ? _tokenURI : super.uri(_tokenID);
    }

    // [O] Permet de récupérer d'éventuels ETH envoyés par erreur sur le SC
    function withdraw() external onlyOwner { payable(msg.sender).transfer(address(this).balance); }

    // Overrides nécessaires
    function _beforeTokenTransfer(address _operator, address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data) internal override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(_operator, _from, _to, _ids, _amounts, _data);
    }

    function supportsInterface(bytes4 _interfaceId) public view virtual override(ERC1155, ERC2981) returns (bool) {
        return super.supportsInterface(_interfaceId);
    }

    // ROYALTIES via ERC-2981
    function setDefaultRoyalty(address _receiver, uint96 _feeNumerator) external onlyOwner {
        _setDefaultRoyalty(_receiver, _feeNumerator);
    }

}