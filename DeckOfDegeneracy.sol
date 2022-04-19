// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./ERC721A.sol";

contract DeckOfDegeneracy is ERC721A, Ownable {
	using Strings for uint256;

	string baseURI;
	string baseExtension = ".json";
	string notRevealedUri;
	uint256 public cost = .1 ether;
	uint256 public maxSupply = 2700;
	uint256 public maxMintPerBatch = 54;
	bool public paused = true;
	bool public revealed = false;
	bool public isPresale = true;
	bool public isMainSale = false;
	bytes32 public whitelistMerkleRoot;
	bool public useWhitelistedAddressesBackup = false;
	mapping(address => uint256) public addressMintedBalance;
	mapping(address => bool) public whitelistedAddressesBackup;

	constructor(
		string memory _name,
		string memory _symbol,
		string memory _notRevealedUri
	) ERC721A(_name, _symbol, maxMintPerBatch, maxSupply) {
		notRevealedUri = _notRevealedUri;
	}

	// internal
	function _baseURI() internal view virtual override returns (string memory) {
		return baseURI;
	}

	function _generateMerkleLeaf(address account)
		internal
		pure
		returns (bytes32)
	{
		return keccak256(abi.encodePacked(account));
	}

	/**
	 * Validates a Merkle proof based on a provided merkle root and leaf node.
	 */
	function _verify(
		bytes32[] memory proof,
		bytes32 merkleRoot,
		bytes32 leafNode
	) internal pure returns (bool) {
		return MerkleProof.verify(proof, merkleRoot, leafNode);
	}

	// require checks refactored for presaleMint() & mint().
	function requireChecks(uint256 _mintAmount) internal {
		require(paused == false, "the contract is paused");
		require(_mintAmount > 0, "need to mint at least 1 NFT");
		require(totalSupply() + _mintAmount <= maxSupply, "max NFT limit exceeded");
		require(
			_mintAmount <= maxMintPerBatch,
			"max NFT per address exceeded"
		);

	}

	/**
	 * Go all in!
	 *
	 * Limit: 2 Whitelist Presale
	 * Only whitelisted individuals can mint presale. We utilize a Merkle Proof to determine who is whitelisted.
	 *
	 * If these cases are not met, the mint WILL fail, and your gas will NOT be refunded.
	 * Please only mint through deckofdegeneracy.io unless you're absolutely sure you know what you're doing!
	 */
	function presaleMint(uint256 _mintAmount, bytes32[] calldata proof)
		public
		payable
	{
		requireChecks(_mintAmount);
		if (msg.sender != owner()) {
			// in the event the Merkle Tree fails (very unlikely), we will revert to a traditional array for the presale list
			if (useWhitelistedAddressesBackup) {
				require(whitelistedAddressesBackup[msg.sender] == true, "user is not whitelisted");
			} else {
				require(
					_verify(
						proof,
						whitelistMerkleRoot,
						_generateMerkleLeaf(msg.sender)
					),
					"user is not whitelisted"
				);
			}
		}
		
		if (msg.sender != owner()) {
			require(msg.value >= cost * _mintAmount, "insufficient funds");
		}

		_safeMint(msg.sender, _mintAmount);
	}


	// mint function for the public sale
	function mint(uint256 _mintAmount)
		public
		payable
	{

		requireChecks(_mintAmount);
		require(isMainSale == true, "sale not on");
		if (msg.sender != owner()) {
			require(msg.value >= cost * _mintAmount, "insufficient funds");
		}

		_safeMint(msg.sender, _mintAmount);
	}

	function getOwnershipData(uint256 tokenId) 
		external
		view
		returns (TokenOwnership memory) {
		return ownershipOf(tokenId);
	}

	function numberMinted(address owner) public view returns (uint256) {
		return _numberMinted(owner);
	}


	function tokenURI(uint256 tokenId)
			public
			view
			virtual
			override
			returns (string memory)
		{
			require(
				_exists(tokenId),
				"ERC721Metadata: URI query for nonexistent token"
			);

			if (revealed == false) {
				return notRevealedUri;
			}

			string memory currentBaseURI = _baseURI();
			return
				bytes(currentBaseURI).length > 0
					? string(
						abi.encodePacked(
							currentBaseURI,
							tokenId.toString(),
							baseExtension
						)
					)
					: "";
	}

	/** Sets the merkle root for the whitelisted individuals. */
	function setWhiteListMerkleRoot(bytes32 merkleRoot) public onlyOwner {
		whitelistMerkleRoot = merkleRoot;
	}

	function setWhitelistedAddressesBackup(address[] memory addresses) public onlyOwner {
		for (uint256 i = 0; i < addresses.length; i++) {
			whitelistedAddressesBackup[addresses[i]] = true;
		}
	}

	function setBackupWhitelistedAddressState(bool state) public onlyOwner {
		useWhitelistedAddressesBackup = state;
	}

	//cost in Wei
	function setCost(uint256 _newCost) public onlyOwner {
		cost = _newCost;
	}

	function setBaseURI(string memory _newBaseURI) public onlyOwner {
		baseURI = _newBaseURI;
	}

	function setBaseExtension(string memory _newBaseExtension)
		public
		onlyOwner
	{
		baseExtension = _newBaseExtension;
	}

	function setRevealedState(bool revealedState) public onlyOwner {
		revealed = revealedState;
	}

	function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
		notRevealedUri = _notRevealedURI;
	}

	function pause(bool _state) public onlyOwner {
		paused = _state;
	}

	function setPresale(bool _state) public onlyOwner {
		isPresale = _state;
	}

	function setMainSale(bool _state) public onlyOwner {
		isMainSale = _state;
	}

	function withdraw() public payable onlyOwner {
		(bool os, ) = payable(owner()).call{value: address(this).balance}("");
		require(os);
	}
}