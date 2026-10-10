using Godot;
using System;

public partial class Tost : Node2D
{
	private Sprite2D spriteNormal;     // Normal ekmek (Sprite2D2)
	private Sprite2D spriteTereyagli;  // Tereyağlı ekmek (Sprite2D)
	private Label resultLabel;         // Ekrandaki Label

	public override void _Ready()
	{
		// Node isimlerini sahnede verdiğin isimlere göre ayarlıyoruz
		spriteNormal = GetNode<Sprite2D>("Sprite2D2");   // Normal ekmek
		spriteTereyagli = GetNode<Sprite2D>("Sprite2D"); // Tereyağlı ekmek
		resultLabel = GetNode<Label>("Label");           // Tost altında Label var

		// Görselleri yükle
		Texture2D normalTexture = (Texture2D)ResourceLoader.Load("res://assets/toasted-bread-slice-on-white-background-png.webp");
		Texture2D butterTexture = (Texture2D)ResourceLoader.Load("res://assets/toasted-bread-with-melting-butter-isolated-on-transparent-background-png.webp");

		spriteNormal.Texture = normalTexture;
		spriteTereyagli.Texture = butterTexture;

		// Başlangıçta normal görünsün
		spriteNormal.Visible = true;
		spriteTereyagli.Visible = false;

		resultLabel.Text = ""; // Başlangıçta boş
	}

	public void SetSide(bool isButter)
	{
		spriteNormal.Visible = !isButter;
		spriteTereyagli.Visible = isButter;
	}

	public override void _PhysicsProcess(double delta)
	{
		// Tost belli bir Y değerine düştüğünde kontrol et
		if (Position.Y > 300)
		{
			float angle = RotationDegrees % 360;
			if (angle > 90 && angle < 270)
			{
				SetSide(true); // tereyağlı taraf
				resultLabel.Text = "Kaybettin!";
			}
			else
			{
				SetSide(false); // normal taraf
				resultLabel.Text = "Kazandın!";
			}
		}
	}
}
