/** @type {import('tailwindcss').Config} */
module.exports = {
  content: [
    "./lib/fino/rails/app/views/**/*.html.erb",
    "./lib/fino/rails/app/helpers/**/*.rb"
  ],
  safelist: [
    'bg-pink-50', 'text-pink-700', 'inset-ring-pink-700/10',
    'bg-blue-50', 'text-blue-700', 'inset-ring-blue-700/10',
    'bg-yellow-50', 'text-yellow-700', 'inset-ring-yellow-700/10',
    'bg-purple-50', 'text-purple-700', 'inset-ring-purple-700/10',
    'bg-gray-50', 'text-gray-700', 'inset-ring-gray-700/10'
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
