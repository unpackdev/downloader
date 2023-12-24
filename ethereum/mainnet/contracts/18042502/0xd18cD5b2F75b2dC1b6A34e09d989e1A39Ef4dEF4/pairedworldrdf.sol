// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ISemanticSBT.sol";
import "./Ownable.sol";
import "./Strings.sol";
import "./ReentrancyGuard.sol";

interface SPOProxyInterface {
        
        function addSPO(uint256 tokenId, uint8 predicateIdx, uint8 objectIdx, string memory object) external;
        function removeRDF(uint256 tokenId, uint8 predicateIdx, uint8 objectIdx) external;
        function getObject(uint256 tokenId, uint8 predicateIdx, uint8 objectIdx) external view returns (string memory);
    
}


contract PairedWorldRDF is Ownable, ISemanticSBT, ReentrancyGuard {

    address public _sbt;
    address public _admin;
    SPOProxyInterface public _spoProxy;

    string public _schemaUri;

    string  constant TURTLE_LINE_SUFFIX = " ;\n    ";
    string  constant TURTLE_END_SUFFIX = " .";

    string  constant public ENTITY_PREFIX = ":";
    string  constant public PROPERTY_PREFIX = "p:";
    string  constant public SOUL_PREFIX = "SOUL_";

    string  constant CONCATENATION_CHARACTER = "_";
    string  constant BLANK_SPACE = " ";

    mapping (uint8 => string) public _predicates;
    mapping (string => uint8) public _predicatesToIdx;
    mapping (uint8 => string) public _objectClasses;
    mapping (string => uint8) public _objectClassesToIdx;

    // Predicates have a 1-to-1 mapping to both subjectClasses and objectClasses
    mapping (uint8 => uint8) public _POPairs;
    // _maxPredicate[tokenID] = highest filled predicate for tokenID
    mapping (uint256 => uint8) public _maxPredicate;

    constructor(address sbt, address spoProxy, string memory schemaUri) {
        _sbt = sbt;
        _schemaUri = schemaUri;
        _spoProxy = SPOProxyInterface(spoProxy);
        _predicates[1] = "ownedBy";
        _predicatesToIdx["ownedBy"] = 1;
        _objectClasses[1] = "address";
        _objectClassesToIdx["address"] = 1;
        _POPairs[1] = 1;
    }

    modifier onlyAdmin() {
        require(msg.sender == _admin || msg.sender == owner(), "Only Admin");
        _;
    }

    modifier onlySbt() {
        require(msg.sender == _sbt, "Only callable by the SBT contract");
        _;
    }

    // MARK: - Only Owner
    function setAdmin(address admin) external onlyOwner {
        _admin = admin;
    }

    function setSbt(address sbt) external onlyOwner {
        _sbt = sbt;
    }

    function setSPOProxy(address spoProxy) external onlyOwner {
        _spoProxy = SPOProxyInterface(spoProxy);
    }

    // MARK: - Only Admin
    function setSchemaUri(string memory schemaUri) external onlyAdmin {
        _schemaUri = schemaUri;
    }

    function setPOPair(
        uint8 predicateIdx, 
        string memory predicate, 
        uint8 objectClassIdx, 
        string memory objectClass
    ) external onlyAdmin {
        require(_isStringEmpty(_predicates[predicateIdx]), "Predicate already exists in the same index");
        require(_isStringEmpty(_objectClasses[objectClassIdx]), "Object class already exists in the same index");
        require(!(objectClassIdx == 0 || predicateIdx == 0), "Cannot set reserved index");
        require(_predicatesToIdx[predicate] == 0, "Predicate already exists");
        require(_objectClassesToIdx[objectClass] == 0, "Object class already exists");
        _predicates[predicateIdx] = predicate;
        _predicatesToIdx[predicate] = predicateIdx;
        _objectClasses[objectClassIdx] = objectClass;
        _objectClassesToIdx[objectClass] = objectClassIdx;
        _POPairs[predicateIdx] = objectClassIdx;
    }

    function updatePOPair(
        uint8 predicateIdx, 
        string memory predicate, 
        uint8 objectClassIdx, 
        string memory objectClass
    ) external onlyAdmin {
        require(!_isStringEmpty(_predicates[predicateIdx]), "Predicate doesn't exist. Use setPOPair instead");
        require(!_isStringEmpty(_objectClasses[objectClassIdx]), "Object class doesn't exist. User setPOPair instead");
        require(_POPairs[predicateIdx] == objectClassIdx, "Attempting to beak 1-to-1 PO relationship");
        require(_predicatesToIdx[predicate] == 0 || _predicatesToIdx[predicate] == predicateIdx, "Predicate already exists");
        require(_objectClassesToIdx[objectClass] == 0 || _objectClassesToIdx[objectClass] == objectClassIdx, "Object class already exists");
        _predicates[predicateIdx] = predicate;
        _predicatesToIdx[predicate] = predicateIdx;
        _objectClasses[objectClassIdx] = objectClass;
        _objectClassesToIdx[objectClass] = objectClassIdx;
    }

    // MARK: - onlySbt
    function addSPO(
        uint256 tokenId, 
        uint8 predicateIdx, 
        uint8 objectIdx, 
        string memory object
    ) external nonReentrant onlySbt {
        require(!_isStringEmpty(_predicates[predicateIdx]), "Predicate doesn't exist");
        require(!_isStringEmpty(_objectClasses[objectIdx]), "Object doesn't exist");
        require(_POPairs[predicateIdx] == objectIdx, "Invalid SPO, predicate and object don't match");

        bool creation = _maxPredicate[tokenId] == 0;
        if (!creation) {
            require(predicateIdx != 1, "cannot change owner SPO");
        }

        _spoProxy.addSPO(tokenId, predicateIdx, objectIdx, object);

        if (_isStringEmpty(object)) {
            _maxPredicate[tokenId] = _maxPredicate[tokenId] == predicateIdx ? predicateIdx - 1 : _maxPredicate[tokenId];
        } else {
            _maxPredicate[tokenId] = _maxPredicate[tokenId] < predicateIdx ? predicateIdx : _maxPredicate[tokenId];
        }

        if (creation) {
            emit CreateRDF(tokenId, _buildRdfString(tokenId));
        } else {
            emit UpdateRDF(tokenId, _buildRdfString(tokenId));
        }
    }

    function removeRDF(uint256 tokenId) external nonReentrant onlySbt {
        require(_maxPredicate[tokenId] > 0, "No RDF to remove");
        string memory oldData = _buildRdfString(tokenId);

        for (uint8 i = 1; i <= _maxPredicate[tokenId]; i++) {
            _spoProxy.removeRDF(tokenId, i, _POPairs[i]);
        }

        _maxPredicate[tokenId] = 0;
        emit RemoveRDF(tokenId, oldData);
    }
    
    function rdfOf(uint256 tokenId) external view override onlySbt() returns (string memory) {
        return _buildRdfString(tokenId);
    }

    // MARK: -  Private
    function _buildRdfString(uint256 tokenId) internal view returns (string memory) {
        string memory rdf = "";
        for (uint8 i = 1; i <= _maxPredicate[tokenId]; i++) {
            string memory subject = string(abi.encodePacked(ENTITY_PREFIX, SOUL_PREFIX, Strings.toString(tokenId)));
            string memory predicate = string(abi.encodePacked(PROPERTY_PREFIX, _predicates[i]));
            string memory object = _spoProxy.getObject(tokenId, i, _POPairs[i]);
            if (_isStringEmpty(object)) {
                continue;
            }
            object = string(abi.encodePacked(ENTITY_PREFIX, _objectClasses[_POPairs[i]], CONCATENATION_CHARACTER, object));
            
            // If it's the same subject as the previous iteration, use a semicolon to separate predicate-object pairs
            if (!_isStringEmpty(rdf)) {
                rdf = string(abi.encodePacked(rdf, TURTLE_LINE_SUFFIX, predicate, BLANK_SPACE, object));
            } else {
                rdf = string(abi.encodePacked(rdf, subject, BLANK_SPACE, predicate, BLANK_SPACE, object));
            }
        }
        
        // Add a period at the end if rdf is not empty
        if (!_isStringEmpty(rdf)) {
            rdf = string(abi.encodePacked(rdf, TURTLE_END_SUFFIX));
        }
        
        return rdf;
    }

    function _isStringEmpty(string memory data) internal pure returns (bool) {
        return bytes(data).length == 0;
    }
    
}