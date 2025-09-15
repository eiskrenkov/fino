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
    'bg-gray-50', 'text-gray-700', 'inset-ring-gray-700/10',

    // Flash component dynamic classes
    'bg-green-50', 'bg-green-100', 'text-green-400', 'text-green-500', 'text-green-800',
    'focus-visible:ring-green-600', 'focus-visible:ring-offset-green-50',
    'bg-red-50', 'bg-red-100', 'text-red-400', 'text-red-500', 'text-red-800',
    'focus-visible:ring-red-600', 'focus-visible:ring-offset-red-50',
    'bg-yellow-100', 'text-yellow-400', 'text-yellow-500', 'text-yellow-800',
    'focus-visible:ring-yellow-600', 'focus-visible:ring-offset-yellow-50',
    'bg-blue-100', 'text-blue-400', 'text-blue-500', 'text-blue-800',
    'focus-visible:ring-blue-600', 'focus-visible:ring-offset-blue-50',
    'bg-gray-100', 'text-gray-400', 'text-gray-500', 'text-gray-800',
    'focus-visible:ring-gray-600', 'focus-visible:ring-offset-gray-50'
  ],
  theme: {
    extend: {},
  },
  plugins: [],
}
