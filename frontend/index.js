const express = require("express");
const dotenv = require("dotenv");

dotenv.config();

const app = express();

app.set("view engine", "ejs");
app.use(express.urlencoded({ extended: false }));

const backendUrl = process.env.BACKEND_URL || "http://localhost:5000";

app.get("/", (req, res) => {
  res.render("index", { error: null });
});

app.post("/submit", async (req, res) => {
  try {
    const response = await fetch(`${backendUrl}/submit`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        name: req.body.name,
        age: req.body.age,
        city: req.body.city,
      }),
    });

    if (!response.ok) {
      throw new Error(`Backend returned ${response.status}`);
    }

    res.render("success");
  } catch (err) {
    console.error("Failed to submit form:", err);
    res.status(502).render("index", {
      error: "Unable to submit the form.",
    });
  }
});

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`Server is running on ${PORT}`);
});
