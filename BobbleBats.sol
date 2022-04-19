// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ERC721A.sol";

contract BobbleBats is ERC721A, Ownable, ReentrancyGuard {
	using Strings for uint256;
	string baseURI;
	string baseExtension = ".json";
	uint256 public cost = .03 ether;
	uint256 public maxSupply = 6666;
	uint256 public maxMintPerBatch = 20;
	mapping(address => uint256) public addressFreeMintBalance;
	uint256 public freeMintSupply = 1337;
	uint256 public freeMintsClaimed = 0;

	constructor(
		string memory _name,
		string memory _symbol,
		string memory _notRevealedUri
	) ERC721A(_name, _symbol, maxMintPerBatch, maxSupply) {
	}

	// internal
	function _baseURI() internal view virtual override returns (string memory) {
		return baseURI;
	}


	function freeMintsRemaining() public view returns (uint256) {
		return freeMintSupply - freeMintsClaimed;
	}


	function mint(uint256 _mintAmount)
		public
		payable
        nonReentrant
	{
		require(_mintAmount <= 20, "20 mint max per txn");
		require(totalSupply() + _mintAmount <= maxSupply, "not enough NFTs remaining");
		if (msg.value == 0) {
			require(freeMintsClaimed + _mintAmount <= freeMintSupply, "not enough free mints remaining");
			freeMintsClaimed += _mintAmount;
		} else {
			if (msg.sender != owner()) {
				// first 444 are free
				if (totalSupply() + _mintAmount > freeMintSupply) {
					require(msg.value >= cost * _mintAmount, "insufficient funds");
				}
			}
		}

		_safeMint(msg.sender, _mintAmount);
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


	function withdraw() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        payable(0xD9462637CBe909BD96bBB56e7dd66AB782C7551E).transfer(balance * 60 / 100);
        payable(owner()).transfer(balance * 40 / 100);
  	}
}