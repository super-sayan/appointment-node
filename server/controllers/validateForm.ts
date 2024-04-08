const Yup = require("yup");
const jwt = require("jsonwebtoken");

const formSchemaLogin = Yup.object({
  email: Yup.string()
    .required("Email is required")
    .matches(
      /[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,4}$/,
      "Email must be valid"
    ),
  password: Yup.string()
    .required("Password is required")
});

const formSchemaSignup = Yup.object({
  email: Yup
    .string()
    .required('Please Enter your Email')
    .matches(
      /[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,4}$/,
      "Email must be valid"
    ),
  name: Yup
    .string()
    .required('Please Enter your Full Name')
    .matches(
      /^[a-zA-Z]+\s[a-zA-Z]+$/,
      "Must contain your First and Last name in English, devided by space"
    ),
  password: Yup
    .string()
    .required('Please Enter your password')
    .matches(
      /^(?=.*[a-z])(?=.*[A-Z])(?=.*[0-9])(?=.*[!@#\$%\^&\*])(?=.{8,})/,
      "Must Contain at least 8 Characters, One Uppercase, One Lowercase, One Number and one special case Character"
    ),
  password2: Yup
    .string()
    .required('You have to confirm your password')
    .oneOf([Yup.ref("password"), null], "Passwords must match")
});

const formSchemaPost = Yup.object({
  email: Yup
    .string()
    .required('Please Enter your Email')
    .matches(
      /[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,4}$/,
      "Email must be valid"
    ),
  name: Yup
    .string()
    .required('Please Enter your Full Name')
    .matches(
      /^[a-zA-Z]+\s[a-zA-Z]+$/,
      "Must contain your First and Last name in English, devided by space"
    ),
  meal_kind: Yup
    .string()
    .required('Please choose your which type of Meal do you prefer')
    .test('valid-meal', 'Choose meal from the list', (value: string | undefined) => {
      if (!value) return false;
      return ["Breakfast", "Business Lunch", "Dinner"].includes(value);
    }),
  date: Yup
    .string()
    .required('Please choose the Date of your visit')
    .test('valid-date', 'Date must be from tomorrow and up to 3 months', (value: string | undefined) => {
      if (!value) return false;
      const selectedDate = new Date(value);
      const tomorrow = new Date();
      tomorrow.setDate(tomorrow.getDate());
      const threeMonthsLater = new Date();
      threeMonthsLater.setMonth(threeMonthsLater.getMonth() + 3);
      return selectedDate >= tomorrow && selectedDate <= threeMonthsLater;
    }),
  time: Yup
    .string()
    .required('Please choose the Time of your visit')
    .test('valid-time', 'Time must be between 9 and 18', (value: string | undefined) => {
      if (!value) return false;
      const hours = parseInt(value.split(':')[0]);
      const minutes = parseInt(value.split(':')[1]);
      return (hours >= 9 && hours <= 17
        && minutes <= 59) || (hours === 18 && minutes === 0);
    }),
  appointment_remark: Yup
    .string()
});

const validateLoginForm = (req, res) => {
  const formData = req.body;
  formSchemaLogin
    .validate(formData)
    .then(() => {
      console.log("form is good");
    })
    .catch((err) => {
      res.status(422).send();
      console.log(err.errors);
    });
};

const validateSignupForm = (req, res) => {
  const formData = req.body;
  formSchemaSignup
    .validate(formData)
    .then(() => {
      console.log("form is good");
    })
    .catch((err) => {
      res.status(422).send();
      console.log(err.errors);
    });
};

const validatePostForm = (req, res) => {
  const formData = req.body;
  // Extract token from request headers
  const token = req.headers.authorization.split(" ")[1];
  jwt.verify(token, process.env.JWT_SECRET, (err, decoded) => {
    if (err) {
      return res.status(401).json({ message: "Unauthorized" });
    }
    // Check if the email in the form matches the decoded email from the token
    if (formData.email !== decoded.email) {
      return res.status(403).json({ message: "Email does not match the logged-in user" });
    }
    console.log("Form is good");
    // Proceed with further validation or processing
  });
};

export { validateLoginForm, validateSignupForm, validatePostForm };
