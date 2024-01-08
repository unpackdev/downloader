// SPDX-License-Identifier: UNLICENSE
pragma solidity ^0.8.0;


library MutationLib {

	bytes32 constant MUTATION_STORAGE_POSITION = keccak256('wtf.fuckyous.mutation0.storage');

	struct MutationStorage {
		bool mutationStart;
		uint mutationPrice;
		mapping(uint => string) mutationName;
		mapping(uint => string) mutationText;
		mapping(uint => string) mutationDesc;
		mapping(uint => uint) mutationFenotype;
		mapping(uint => bytes16) mutationTemplate;
	}

	function mutationStorage() internal pure returns (MutationStorage storage ms) {
		bytes32 position = MUTATION_STORAGE_POSITION;
		assembly {
			ms.slot := position
		}
	}

  function mutateName(uint tokenId, string memory name) internal {
    MutationStorage storage s = mutationStorage();
    s.mutationName[tokenId] = name;
  }
  function mutateText(uint tokenId, string memory text) internal {
    MutationStorage storage s = mutationStorage();
    s.mutationText[tokenId] = text;
  }
  function mutateDesc(uint tokenId, string memory desc) internal {
    MutationStorage storage s = mutationStorage();
    s.mutationDesc[tokenId] = desc;
  }
  function mutateFenotype(uint tokenId, uint fenotype) internal {
    MutationStorage storage s = mutationStorage();
    s.mutationFenotype[tokenId] = fenotype;
  }
  function mutateTemplate(uint tokenId, bytes16 template) internal {
    MutationStorage storage s = mutationStorage();
    s.mutationTemplate[tokenId] = template;
  }

	function setMutationStart(bool start) internal {
    MutationStorage storage s = mutationStorage();
    s.mutationStart = start;
  }
	function setMutationPrice(uint price) internal {
    MutationStorage storage s = mutationStorage();
    s.mutationPrice = price;
  }
}
